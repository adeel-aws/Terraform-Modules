variable "ami_id" {
  description = "AMI ID to use for EC2 instance"
  type        = string
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "web-server"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "Subnet ID to launch EC2 in"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to EC2"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "SSH key name"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "Optional user_data script for EC2"
  type        = string
  default     = ""
}

variable "enable_ssm" {
  description = "Whether to attach SSM IAM role to EC2"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name for naming convention (dev/test/prod)"
  type        = string
  default     = "dev"
}