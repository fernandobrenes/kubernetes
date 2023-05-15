#! /bin/bash

# PreReqs https://kubernetes.io/docs/setup/production-environment/container-runtimes/

set -euxo pipefail

# Kubernetes Version
VERSION="$(echo ${KUBERNETES_VERSION} | grep -oE '[0-9]+\.[0-9]+')"

# DNS Setting
sudo mkdir /etc/systemd/resolved.conf.d/
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=${DNS_SERVERS}
EOF

# Disable swap 
sudo systemctl mask swap.img.swap
sudo sed -i '/\tswap\t/d' /etc/fstab
sudo swapoff -a

# Disable iSCSI Services to avoid A start job is running for wait for network to be configured. Ubuntu server 17.10 - systemctl show -p WantedBy network-online.target
sudo systemctl --now disable iscsid.service
sudo systemctl --now disable open-iscsi.service


# Change DHCP4 to no in /etc/netplan/01-netcfg.yaml and run sudo netplan apply
sudo sed -i -e 's/true/false/g' /etc/netplan/01-netcfg.yaml
sudo netplan apply

# Keeps the swaf off during reboot
#sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Forwarding IPv4 and letting iptables see bridged traffic
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
kernel.watchdog_thresh = 60
kernel.softlockup_panic = 0
EOF

# Apply sysctl params without reboot
sudo sysctl --system

echo "Kubernetes Requirements Completed"

# Containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Load Kernel Modules
sudo modprobe overlay
sudo modprobe br_netfilter

echo "ContainerD Runtime Configured Successfully"

# Installing kubeadm, kubelet and kubectl
sudo apt-get update -y

# Google Cloud public signing key
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# Add Kubernetes apt repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get update -y
sudo apt-get install -y jq
sudo apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"
sudo apt-mark hold kubelet kubeadm kubectl
sudo sleep 30
sudo systemctl start kubelet

# AutoCompletion
#sudo apt-get install bash-completion
#source /usr/share/bash-completion/bash_completion
#sudo echo 'source <(kubectl completion bash)' >>~/.bashrc
#source ~/.bashrc

local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
${ENVIRONMENT}
EOF



