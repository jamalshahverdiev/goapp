#!/bin/bash 

export CLUSTER_NAME="${TF_VAR_cluster_name}" 
export AWS_REGION="${TF_VAR_region}"

terraform -chdir=.amazon init
terraform -chdir=.amazon apply -auto-approve

eksctl utils associate-iam-oidc-provider \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --approve

eksctl create addon --name aws-ebs-csi-driver \
    --cluster "${CLUSTER_NAME}" \
    --service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole \
    --force

eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster "${CLUSTER_NAME}" \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --override-existing-serviceaccounts \
    --approve

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

kubectl apply -f .agones/gameserver.yaml

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