variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
}

variable "records" {
  description = "Flexible DNS records"
  type        = map(any)
}