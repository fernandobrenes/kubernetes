# GET THE 
config_path="/vagrant/configs"

echo "Installing nginx-ingress controller..."

NGINX_VERSION=$(grep -E '^\s*nginx-ingress:' /vagrant/settings.yaml | sed -E 's/[^:]+: *//' | tr -d '\012\015')
sudo -i -u vagrant kubectl apply -f "https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v${NGINX_VERSION}/deploy/static/provider/baremetal/deploy.yaml"



