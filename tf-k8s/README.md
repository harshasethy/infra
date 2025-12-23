# Terraform Kubernetes on AWS

## Overview
This configuration provisions a minimal Kubernetes cluster on AWS using Terraform. It creates one control-plane node and a configurable number of worker nodes inside the default VPC, installs containerd and the Kubernetes components with cloud-init scripts, and outputs the public IP addresses so you can connect and finish the cluster bootstrap.

## Architecture Highlights
- Uses the AWS default VPC and its subnets for networking.
- Creates a security group that opens SSH (22), the Kubernetes API (6443), and the default NodePort range (30000-32767).
- Launches one control-plane instance and spot instances for workers, each with the canonical Ubuntu 22.04 LTS AMI.
- Runs `scripts/install_k8s.sh` to install containerd and Kubernetes 1.29 components, then role-specific scripts for control-plane initialization and worker preparation.
- Leaves the final `kubeadm join` step to be executed manually on each worker so you can control token lifetime and approval.

## Prerequisites
- Terraform 1.4+ installed locally.
- An AWS account with credentials configured via environment variables, `~/.aws/credentials`, or an active AWS profile.
- An existing EC2 key pair in the target region; its name should match the `key_name` variable so you can SSH into the nodes.
- (Optional) `ssh` access from your workstation to the created instances.

## Usage
1. Review or update the variable values in `terraform.tfvars` (or supply overrides via `-var`). At minimum, set `key_name` to an existing EC2 key pair and adjust instance types, worker count, or disk size if needed.
2. Initialize Terraform and download provider plugins:
   ```bash
   terraform init
   ```
3. Review the infrastructure plan:
   ```bash
   terraform plan
   ```
4. Apply the plan to create the cluster foundation:
   ```bash
   terraform apply
   ```
5. Note the `control_plane_ip` and `worker_ips` outputs when apply completes.
6. SSH into the control-plane node to finish setup:
   ```bash
   ssh -i <path-to-key.pem> ubuntu@$(terraform output -raw control_plane_ip)
   ```
   - Generate a join token and command:
     ```bash
     sudo kubeadm token create --print-join-command
     ```
   - (Optional) Copy `/home/ubuntu/.kube/config` to your workstation if you want to manage the cluster locally.
7. SSH into each worker node and run the printed `kubeadm join ...` command to attach it to the cluster.

## Customization
| Variable | Description | Default |
|----------|-------------|---------|
| `region` | AWS region for all resources | `us-east-1` |
| `key_name` | Name of the AWS EC2 key pair used for SSH | _(none)_ |
| `control_plane_instance_type` | Instance type for the control-plane node | `t3.medium` |
| `worker_instance_type` | Instance type for worker nodes | `t3.small` |
| `worker_count` | Number of worker nodes to create | `2` |
| `disk_size` | Root volume size (GiB) for all nodes | `20` |

Edit `variables.tf` or supply `-var`/`-var-file` flags to change these values. You can also duplicate the module to target multiple regions or VPCs if desired.

## Scripts
- `scripts/install_k8s.sh`: Common bootstrap script that updates the OS, configures containerd, and installs kubelet/kubeadm/kubectl 1.29.
- `scripts/control_plane.sh`: Initializes the cluster with `kubeadm init` using a Calico CNI pod network CIDR of `192.168.0.0/16`, and configures `kubectl` for the default user.
- run kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
- `scripts/worker.sh`: Placeholder that reminds you to run the `kubeadm join` command manually after you generate it on the control plane.
On Control Plane
      - Check and run kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml , if CP is not ready
and copy /etc/kubernetes/admin.conf from CP to workker node at ~/.kube/config
on worker - run 
            chmod 600 ~/.kube/config
            kubectl get nodes

## Cleanup
Destroy all created infrastructure once you no longer need the cluster:
```bash
terraform destroy
```

## Notes & Limitations
- Resources are created in the default VPC; adjust data sources if you need a custom VPC or subnets.
- Worker instances run as EC2 Spot; they can be reclaimed by AWS. Adjust `instance_market_options` if on-demand capacity is required.
- The security group allows access from anywhere; restrict CIDR ranges for production use.
- The kubeadm join command expires; regenerate it if workers are added later or if provisioning takes longer than the token TTL.
