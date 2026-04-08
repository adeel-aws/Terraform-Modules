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

variable "ec2_ingress_rules" {
  description = "List of ingress rules for EC2 Security Group. Each rule needs from_port, to_port, protocol, cidr_blocks"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}