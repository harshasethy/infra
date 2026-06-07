# Monitoring setup

This folder contains the Prometheus monitoring installation assets for the cluster.

## Files

- `install-monitoring.sh` - installs the Prometheus Helm stack and applies custom alert rules.
- `values.yaml` - Helm values for the `kube-prometheus-stack` chart.
- `namespace.yaml` - creates the `monitoring` namespace.
- `alerts/custom-alerts.yaml` - custom `PrometheusRule` definitions.

## Usage

### Run from a cluster node

If you are running this on the Kubernetes control plane node, make sure the node has access to the cluster and the control-plane kubeconfig is available at `/etc/kubernetes/admin.conf`.

```bash
cd /path/to/monitoring
./install-monitoring.sh
```

### Run from a machine with kubeconfig access

If you want to run this from your laptop, ensure `kubectl` can access the cluster and `helm` is installed.

```bash
export KUBECONFIG=~/.kube/config
cd /path/to/monitoring
./install-monitoring.sh
```

### Run from a laptop via SSH to the control plane

If your laptop cannot access the cluster directly, use the remote wrapper to copy the monitoring installer to the control plane and execute it there.

```bash
cd /path/to/monitoring
./install-monitoring-remote.sh --host <control-plane-ip> --key <path/to/key.pem> --user ubuntu
```

## Notes

- `install-monitoring.sh` will install Helm automatically if it is not present on the host.
- The script uses `--validate=false` for `kubectl apply` to avoid API discovery issues when validating manifests.
