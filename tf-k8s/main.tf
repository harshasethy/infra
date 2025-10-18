data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Allow SSH and Kubernetes traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-sg"
  }
}

resource "aws_eip" "control_plane_eip" {
  instance = aws_instance.control_plane.id
  domain   = "vpc"

  tags = {
    Name = "k8s-control-plane-eip"
  }

  depends_on = [aws_instance.control_plane]
}

# Control Plane
resource "aws_instance" "control_plane" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.control_plane_instance_type
  subnet_id                   = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.disk_size
  }

  user_data = join("\n", [
    file("${path.module}/scripts/install_k8s.sh"),
    "",
    file("${path.module}/scripts/control_plane.sh"),
  ])

  tags = {
    Name = "k8s-control-plane"
  }
}

# Worker Nodes
resource "aws_instance" "workers" {
  count                       = var.worker_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.worker_instance_type
  subnet_id                   = element(data.aws_subnets.default.ids, count.index)
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  instance_market_options {
    market_type = "spot"
  }

  root_block_device {
    volume_size = var.disk_size
  }

  user_data = join("\n", [
    file("${path.module}/scripts/install_k8s.sh"),
    "",
    file("${path.module}/scripts/worker.sh"),
  ])

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}

# Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
