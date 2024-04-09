helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-operator prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

kubectl get crd servicemonitors.monitoring.coreos.com
kubectl get prometheus --all-namespaces
kubectl get prometheus prometheus-operator-kube-p-prometheus -n monitoring -o yaml | kubectl neat

helm template goapp ./chart --namespace goapp --create-namespace
helm install goapp ./chart --namespace goapp --create-namespace
kubectl get servicemonitor -n goapp

