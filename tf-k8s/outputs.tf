output "control_plane_ip" {
  value = aws_instance.control_plane.public_ip
}

output "worker_ips" {
  value = [for w in aws_instance.workers : w.public_ip]
}