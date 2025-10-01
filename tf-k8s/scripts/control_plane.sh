#!/bin/bash
set -e

# Initialize Kubernetes control plane
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Configure kubeconfig for ubuntu user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico CNI
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml