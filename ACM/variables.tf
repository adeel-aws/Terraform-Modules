variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name for ACM certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional SAN domains"
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------
# ROUTE53 AUTO VALIDATION
# ---------------------------------------------------------
variable "auto_validate_via_route53" {
  description = "If true, automatically creates Route53 DNS validation records and waits for validation. If false, outputs validation records for manual DNS entry."
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID. Required only when auto_validate_via_route53 = true"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply on resources"
  type        = map(string)
  default     = {}
}