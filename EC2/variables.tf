variable "ami_id" {
  type        = string
  description = "AMI ID"
}

variable "instance_name" {
  type    = string
  default = "ec2"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "key_name" {
  type    = string
  default = ""
}

variable "user_data" {
  type    = string
  default = ""
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "myapp"
}

# ---------------- SSM ----------------
variable "enable_ssm" {
  type    = bool
  default = false
}

# ---------------- Storage ----------------
variable "root_volume_size" {
  type    = number
  default = 20
}

variable "root_volume_type" {
  type    = string
  default = "gp3"
}

variable "enable_volume_encryption" {
  type    = bool
  default = true
}

# ---------------- Monitoring ----------------
variable "enable_detailed_monitoring" {
  type    = bool
  default = false
}

# ---------------- Elastic IP ----------------
variable "enable_eip" {
  type    = bool
  default = false
}

# ---------------- Extra tags ----------------
variable "tags" {
  type    = map(string)
  default = {}
}