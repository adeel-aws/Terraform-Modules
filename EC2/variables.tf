variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "web-server"
}

variable "ami_id" {
  description = "AMI ID to use for EC2"
  type        = string
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

variable "vpc_sg_ids" {
  description = "List of security group IDs for EC2"
  type        = list(string)
}

variable "key_name" {
  description = "Key pair for SSH access"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "Optional user_data script"
  type        = string
  default     = ""
}

variable "enable_ssm" {
  description = "Whether to attach SSM IAM role"
  type        = bool
  default     = false
}