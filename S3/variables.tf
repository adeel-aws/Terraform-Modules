variable "bucket_name" {
  type = string
}

variable "project_name" {
  type    = string
  default = "myapp"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "force_destroy" {
  type    = bool
  default = false
}

# 🔥 NEW: Core design switch (industry standard)
variable "access_mode" {
  type    = string
  default = "private"

  validation {
    condition     = contains(["private", "public", "cloudfront"], var.access_mode)
    error_message = "access_mode must be private, public, or cloudfront"
  }
}

# Website hosting
variable "enable_static_website" {
  type    = bool
  default = false
}

variable "index_document" {
  type    = string
  default = "index.html"
}

variable "error_document" {
  type    = string
  default = "error.html"
}

# Versioning
variable "enable_versioning" {
  type    = bool
  default = false
}

# Lifecycle
variable "enable_lifecycle_rule" {
  type    = bool
  default = false
}

variable "lifecycle_expiration_days" {
  type    = number
  default = 30
}

variable "lifecycle_transition_days" {
  type    = number
  default = 0
}

variable "lifecycle_storage_class" {
  type    = string
  default = "STANDARD_IA"
}

# Logging
variable "enable_logging" {
  type    = bool
  default = false
}

variable "log_bucket" {
  type    = string
  default = ""
}

variable "log_prefix" {
  type    = string
  default = ""
}

# 🔐 CloudFront integration (optional, NOT required)
variable "cloudfront_oac_arn" {
  type    = string
  default = null
}