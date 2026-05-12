variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "db_name" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "db_port" {
  type = number
}

variable "multi_az" {
  type = bool
}

variable "backup_retention" {
  type = number
}

variable "deletion_protection" {
  type = bool
}
variable "enable_ssm_parameters" {
  description = "Store DB connection details in SSM Parameter Store"
  type        = bool
  default     = false
}