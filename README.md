📦 Infrastructure Repository

This repository contains Infrastructure as Code (IaC) developed from my hands-on experience in managing and automating cloud environments. It reflects the best practices I’ve adopted over time while working with tools like Terraform, Ansible, and AWS, with a focus on:
	•	🔧 Automated provisioning of cloud resources
	•	🔒 Secure and scalable architecture patterns
	•	🧱 Modular, reusable components for maintainability

## What’s included

- `tf-k8s/` — Terraform for provisioning a Kubernetes cluster on AWS.
- `scripts/` — bootstrap scripts for installing containerd and Kubernetes on control plane and worker nodes.
- `monitoring/` — Prometheus/Grafana monitoring setup, custom alerts, and install scripts.
- `docs/` — architecture diagrams, monitoring dashboard guidance, alert examples, and cleanup instructions.

## Important notes

- This repository can create billable AWS resources such as EC2 instances and EBS volumes.
- Destroy resources when you are finished to avoid unexpected charges.

## Documentation

See `docs/README.md` for a guided list of architecture, monitoring, and cleanup documentation.

⸻
