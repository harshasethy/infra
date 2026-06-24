# Cleanup

Use these steps to tear down the infrastructure and monitoring stack when you are finished.

## Terraform cleanup

From the `tf-k8s/` directory, destroy all AWS resources provisioned by Terraform:

```bash
cd tf-k8s
terraform destroy
```

If you want to bypass interactive approval:

```bash
terraform destroy -auto-approve
```

## Monitoring cleanup

If the monitoring stack was installed, remove it and delete the `monitoring` namespace:

```bash
cd monitoring
helm uninstall kube-prometheus-stack -n monitoring || true
kubectl delete namespace monitoring --ignore-not-found
```

## Cost warning

This repository can create billable AWS resources such as EC2 instances and EBS volumes.
Always destroy or remove resources when you are done to avoid unexpected charges.

- Control-plane and worker EC2 instances incur hourly costs.
- EBS storage incurs additional per-GB charges.
- Public IP addresses may incur allocation costs.

## Optional cleanup

If you created an SSH key or local kubeconfig files during setup, clean them up manually from your workstation.
