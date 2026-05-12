variable "project_name" { 
  type = string 
}
variable "environment"  { type = string }

variable "vpc_name" { type = string }
variable "vpc_cidr" { type = string }

variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "azs" { type = list(string) }

variable "enable_nat_gateway" { 
  type = bool 
  default = false 
  }
variable "create_eip" { 
  type = bool 
  default = true 
  }

# SG toggles (ALL INDEPENDENT)
variable "create_elb_sg" { 
  type = bool 
  default = false 
  }
variable "create_app_sg" { 
  type = bool 
  default = true 
  }
variable "create_db_sg"  { 
  type = bool 
  default = false 
  }

variable "tags" {
  type    = map(string)
  default = {}
}

variable "elb_ingress_rules" {
  description = "Ingress rules for ELB SG"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []
}

variable "app_ingress_rules" {
  description = "Ingress rules for APP SG"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []
}

variable "db_ingress_rules" {
  description = "Ingress rules for DB SG"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []
}