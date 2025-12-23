#!/bin/bash
set -e

# Ensure HOME exists (cloud-init may invoke the script with HOME unset)
: "${HOME:=/root}"

# Initialize Kubernetes control plane
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Configure kubeconfig for root (cloud-init executes as root)
mkdir -p "$HOME/.kube"
sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"
# Ensure kubectl uses the freshly generated admin kubeconfig even if HOME is unset later
export KUBECONFIG=/etc/kubernetes/admin.conf

# Also set up kubectl for the default ubuntu user when present
if id ubuntu >/dev/null 2>&1; then
  sudo mkdir -p /home/ubuntu/.kube
  sudo cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
fi

# Wait for the Kubernetes API server to become ready before applying addons
api_ready=false
for attempt in $(seq 1 60); do
  if kubectl --kubeconfig "$KUBECONFIG" get --raw='/readyz?verbose' >/dev/null 2>&1; then
    api_ready=true
    break
  fi
  sleep 10
done

if [ "$api_ready" != "true" ]; then
  echo "Kubernetes API server not ready after waiting, aborting CNI install" >&2
  exit 1
fi

# Install Calico CNI
kubectl --kubeconfig "$KUBECONFIG" apply -f https://docs.projectcalico.org/manifests/calico.yaml
