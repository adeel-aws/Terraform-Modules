variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Delete bucket even if not empty"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for bucket"
  type        = map(string)
  default     = {}
}