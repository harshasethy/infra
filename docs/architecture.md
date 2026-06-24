# Architecture

This project provisions a small Kubernetes cluster on AWS and installs the Prometheus monitoring stack.
The architecture is intentionally simple so it can be deployed quickly while still supporting observability and alerting.

## Components

- **Terraform `tf-k8s/`** provisions AWS infrastructure:
  - AWS default VPC and public subnets
  - one control-plane EC2 instance
  - configurable worker EC2 instances
  - security group rules for SSH, Kubernetes API, NodePort, Grafana, and Calico networking
- **Cluster bootstrap scripts** in `scripts/` install containerd, Kubernetes components, and initialize the cluster.
- **Monitoring** is deployed from `monitoring/` using the `kube-prometheus-stack` Helm chart.
- **Grafana** provides dashboards for node metrics and Kubernetes health.
- **PrometheusRule alerts** are configured in `monitoring/alerts/custom-alerts.yaml`.

## High-level topology

```mermaid
flowchart LR
  subgraph AWS Default VPC
    direction TB
    CP["Control Plane\nEC2 instance"]
    W1["Worker Node 1\nEC2 instance"]
    W2["Worker Node 2\nEC2 instance"]
  end

  subgraph Kubernetes Cluster
    direction TB
    APIServer["kube-apiserver"]
    Controller["kube-controller-manager"]
    Scheduler["kube-scheduler"]
    ETCD["etcd"]
    CNI["Calico / CNI"]
  end

  subgraph Monitoring Stack
    direction TB
    Prometheus["Prometheus"]
    Grafana["Grafana"]
    Alertmanager["Alertmanager"]
    NodeExporter["Node Exporter"]
  end

  CP --> APIServer
  CP --> Controller
  CP --> Scheduler
  CP --> ETCD
  CP --> CNI
  W1 --> CNI
  W2 --> CNI
  W1 --> NodeExporter
  W2 --> NodeExporter
  Prometheus --> NodeExporter
  Prometheus --> APIServer
  Grafana --> Prometheus
  Alertmanager --> Prometheus
  Grafana -->|HTTP 3000| CP

  style AWS Default VPC fill:#f5f7ff,stroke:#a0b0d0
  style Kubernetes Cluster fill:#eef7f2,stroke:#7bb97b
  style Monitoring Stack fill:#fff7e6,stroke:#e3b96c
```

## Diagram asset

A visual diagram is available at `docs/screenshots/architecture-diagram.svg`.

## Notes

- The cluster uses the default VPC for simplicity; adjust the Terraform configuration if you need a custom VPC.
- Grafana runs on port `3000` by default when the monitoring stack is installed.
- Alerting can be extended by editing `monitoring/alerts/custom-alerts.yaml` and configuring receivers in `monitoring/values.yaml`.
