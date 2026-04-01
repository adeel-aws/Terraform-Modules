variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

# NAT toggle
variable "enable_nat_gateway" {
  type    = bool
  default = false
}

# Optional Elastic IP for NAT
variable "create_eip" {
  type    = bool
  default = true
}

# Optional EC2 Security Group
variable "create_ec2_sg" {
  type    = bool
  default = true
}

# Security Groups
variable "allowed_ssh_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "allowed_http_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "db_port" {
  type    = number
  default = 3306
}