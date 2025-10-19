output "control_plane_ip" {
  value       = aws_eip.control_plane_eip.public_ip
  description = "The Elastic IP of the control plane node"
}

output "worker_ips" {
  value       = [for w in aws_instance.workers : w.public_ip]
  description = "Public IPs of worker nodes"
}
