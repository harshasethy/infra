#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE=monitoring
NAMESPACE=monitoring
VALUES_FILE="${DIR}/values.yaml"
ALERTS_FILE="${DIR}/alerts/custom-alerts.yaml"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required to install Prometheus."
  exit 1
fi

if [ -z "${KUBECONFIG:-}" ] && [ -f /etc/kubernetes/admin.conf ]; then
  export KUBECONFIG=/etc/kubernetes/admin.conf
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "kubectl cannot reach a Kubernetes cluster."
  echo "Ensure your kubeconfig is set and the API server is accessible before running this script."
  exit 1
fi

install_helm() {
  if command -v helm >/dev/null 2>&1; then
    return 0
  fi

  echo "Installing Helm..."
  tmpdir=$(mktemp -d)
  trap 'rm -rf "${tmpdir}"' EXIT
  curl -fsSL https://get.helm.sh/helm-v3.12.3-linux-amd64.tar.gz -o "${tmpdir}/helm.tar.gz"
  tar -xzf "${tmpdir}/helm.tar.gz" -C "${tmpdir}"
  sudo mv "${tmpdir}/linux-amd64/helm" /usr/local/bin/helm
  sudo chmod +x /usr/local/bin/helm
}

if ! command -v helm >/dev/null 2>&1; then
  install_helm
fi

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl apply --validate=false -f "${DIR}/namespace.yaml"

helm upgrade --install "${RELEASE}" prometheus-community/kube-prometheus-stack \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --values "${VALUES_FILE}"

kubectl apply --validate=false -f "${ALERTS_FILE}"

echo "Prometheus stack installed in namespace ${NAMESPACE}."
echo "Grafana is available through the monitoring namespace service."
echo "To port-forward Grafana: kubectl port-forward -n ${NAMESPACE} svc/monitoring-grafana 3000:80"
