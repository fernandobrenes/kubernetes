# GET THE 
config_path="/vagrant/configs"

METALLB_VERSION=$(grep -E '^\s*metallb:' /vagrant/settings.yaml | sed -E 's/[^:]+: *//' | tr -d '\012\015')
sudo -i -u vagrant kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/v${METALLB_VERSION}/config/manifests/metallb-native.yaml"

echo "Defining The IPs To Assign To The Load Balancer Services..."

cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.0.50-10.0.0.80
EOF

echo "Set L2Advertisement..."

cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF