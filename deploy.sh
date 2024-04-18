helm upgrade -n devops-test-task --create-namespace -i devops-test-task .helm/

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add ricoberger https://ricoberger.github.io/helm-charts
helm repo update
helm upgrade -i prometheus -n monitoring --create-namespace prometheus-community/prometheus -f .monitoring/prometheus.yaml
helm upgrade -i grafana -n monitoring --create-namespace grafana/grafana -f .monitoring/grafana.yaml

kubectl apply -n monitoring -f .monitoring/dashboard.yaml
helm upgrade -i prometheus-redis-exporter -n devops-test-task --create-namespace prometheus-community/prometheus-redis-exporter -f .monitoring/redis-exporter.yaml

# kubectl apply -n devops-test-task -f .monitoring/script.yaml
helm upgrade -i script-exporter -n devops-test-task --create-namespace ricoberger/script-exporter -f .monitoring/script-exporter.yaml