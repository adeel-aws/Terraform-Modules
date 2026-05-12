variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "repository_name" {
  type = string
}

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "scan_on_push" {
  type    = bool
  default = true
}

variable "encryption_type" {
  type    = string
  default = "AES256"
}

variable "enable_lifecycle_policy" {
  type    = bool
  default = true
}

variable "max_image_count" {
  type    = number
  default = 10
}

variable "tags" {
  type    = map(string)
  default = {}
}