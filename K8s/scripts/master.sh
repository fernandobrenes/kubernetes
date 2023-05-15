#! /bin/bash

set -euxo pipefail

NODENAME=$(hostname -s)

# Pre Pull Containers for kubeadm 
sudo kubeadm config images pull
echo "Preflight Check Passed: Downloaded All Required Images"

# Create the Cluster
sudo kubeadm init --apiserver-advertise-address=$CONTROL_IP  --apiserver-cert-extra-sans=$CONTROL_IP --pod-network-cidr=$POD_CIDR --service-cidr=$SERVICE_CIDR --node-name $NODENAME --ignore-preflight-errors Swap

# Configuring kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Copy kubectl configuration as Vagrant User to use the Cluster
vagrant_home=$(getent passwd vagrant | cut -d: -f6)
sudo mkdir -p $vagrant_home/.kube
sudo cp -i /etc/kubernetes/admin.conf $vagrant_home/.kube/config
sudo chown $(id -u vagrant):$(id -g vagrant) $vagrant_home/.kube/config

# Save Configs to shared /Vagrant location
# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.
config_path="/vagrant/configs"

if [ -d $config_path ]; then
   rm -f $config_path/*
else
   mkdir -p /vagrant/configs
fi

cp -i /etc/kubernetes/admin.conf /vagrant/configs/config
touch /vagrant/configs/join.sh
chmod +x /vagrant/configs/join.sh       

# Generete kubeadm join command
kubeadm token create --print-join-command > /vagrant/configs/join.sh
sed -i '$s/$/--v=5/' /vagrant/configs/join.sh

# Install Metrics Server
kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml