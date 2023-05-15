# Clone Kube-Prometheus - https://github.com/prometheus-operator/kube-prometheus then follow https://collabnix.com/how-to-setup-prometheus-grafana-on-kubernetes/ - https://www.airplane.dev/blog/grafana-vs-prometheus
echo "Cloning Monitoring Stack"
git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus

# Create a namespace and required CustomResourceDefinitions
echo "Creating namespace monitoring and resources"
kubectl apply --server-side -f manifests/setup
kubectl wait \
	--for condition=Established \
	--all CustomResourceDefinition \
	--namespace=monitoring

# Deploy Prometheus monitoring stack
echo "Deploy Prometheus monitoring stack"
kubectl apply -f manifests/

# Access Grafana
echo "You can access Grafana now with kubectl --namespace monitoring port-forward svc/grafana 3000 and then http://localhost:3000"
echo "Username: admin"
echo "Password: admin"

# Access Prometheus
echo "You can access Prometheus now with kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090 and then http://localhost:9090" 

# Alert Manager Dashboard
echo "You can access Alert Manager Dashboard now with kubectl --namespace monitoring port-forward svc/alertmanager-main 9093 and then http://localhost:9093" 