#!/bin/bash 

export CLUSTER_NAME="${TF_VAR_cluster_name}" 
export TF_VAR_region="${AWS_REGION}"

terraform -chdir=.amazon init
terraform -chdir=.amazon apply -auto-approve

aws eks update-kubeconfig --name ${CLUSTER_NAME} --kubeconfig ~/.kube/config 

eksctl utils associate-iam-oidc-provider \
    --region ${TF_VAR_region} \
    --cluster ${CLUSTER_NAME} \
    --approve

eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster "${CLUSTER_NAME}" \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --role-only \
    --override-existing-serviceaccounts \
    --approve

eksctl create addon --name aws-ebs-csi-driver \
    --cluster "${CLUSTER_NAME}" \
    --service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole \
    --force

eksctl update addon --name aws-ebs-csi-driver --cluster "${CLUSTER_NAME}" \
  --service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole --force

# Goapp
helm upgrade -n devops-test-task --create-namespace -i ${CLUSTER_NAME} .helm/

# Repos
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update

# Monitoring
kubectl create ns monitoring
kubectl apply -n monitoring -f .monitoring/svc-monitoring.yaml
kubectl apply -n monitoring -f .monitoring/certs.yaml
helm upgrade -i prometheus -n monitoring --create-namespace prometheus-community/prometheus -f .monitoring/prometheus.yaml
helm upgrade -i grafana -n monitoring --create-namespace grafana/grafana -f .monitoring/grafana.yaml
helm upgrade -i redis-exporter -n monitoring --create-namespace prometheus-community/prometheus-redis-exporter -f .monitoring/redis-exporter.yaml

kubectl apply -n monitoring -f .monitoring/goapp-exporter.yaml
kubectl apply -n monitoring -f .monitoring/dashboard.yaml

helm repo add agones https://agones.dev/chart/stable
helm repo update
helm upgrade -i agones --namespace agones-system --create-namespace agones/agones

sleep 100

kubectl apply -f .agones/certs.yaml
kubectl apply -f .agones/gameserver.yaml

sleep 100

xonotic_gs_address=$(kubectl get gameservers.agones.dev --output jsonpath="{.items[0].status.addresses[1].address}")
xonotic_gs_port=$(kubectl get gameservers.agones.dev --output jsonpath="{.items[0].status.ports[0].port}")
dns_go=$(kubectl get services -n devops-test-task --output jsonpath="{.status.loadBalancer.ingress[0].hostname}" devops-test-task-goapp-lb)
dns_grafana=$(kubectl get services -n monitoring --output jsonpath="{.status.loadBalancer.ingress[0].hostname}" grafana)

echo ""
echo "Golang: http://${dns_go}"

echo ""
echo "Grafana: http://${dns_grafana}"
echo "User: admin"
echo "Pass: admin"

echo ""
echo "Xonotic: ${xonotic_gs_address}:${xonotic_gs_port}"