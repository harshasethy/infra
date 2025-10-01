variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "SSH key name in AWS"
  type        = string
}

variable "control_plane_instance_type" {
  description = "Instance type for control plane"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.small"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 20
}