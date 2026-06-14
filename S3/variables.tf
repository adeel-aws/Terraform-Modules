variable "bucket_name" {
  description = "Base bucket name — combined with project_name and environment as prefix"
  type        = string
}

variable "project_name" {
  description = "Project name — used as part of the bucket name prefix"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to merge onto all resources"
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Allow bucket deletion even when it contains objects (useful for dev environments)"
  type        = bool
  default     = false
}

# ================================================================
#  ACCESS MODE
#
#  private     — fully private, no public access (default)
#  public      — public GetObject allowed (static sites without CloudFront)
#  cloudfront  — private bucket, accessible only via CloudFront OAC
#                requires cloudfront_distribution_arn to be set
# ================================================================

variable "access_mode" {
  description = "Bucket access mode: private | public | cloudfront"
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "public", "cloudfront"], var.access_mode)
    error_message = "access_mode must be one of: private, public, cloudfront"
  }
}

# ================================================================
#  CLOUDFRONT OAC INTEGRATION
#
#  Pass the CloudFront *distribution* ARN here — NOT the OAC resource ARN.
#  This is used in the bucket policy AWS:SourceArn condition.
#  Format: arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID
# ================================================================

variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN for OAC bucket policy (required when access_mode = cloudfront)"
  type        = string
  default     = null
}

# ================================================================
#  STATIC WEBSITE HOSTING
# ================================================================

variable "enable_static_website" {
  description = "Enable S3 static website hosting"
  type        = bool
  default     = false
}

variable "index_document" {
  description = "Index document for static website hosting"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for static website hosting"
  type        = string
  default     = "error.html"
}

# ================================================================
#  VERSIONING
# ================================================================

variable "enable_versioning" {
  description = "Enable S3 object versioning"
  type        = bool
  default     = false
}

# ================================================================
#  LIFECYCLE RULES
# ================================================================

variable "enable_lifecycle_rule" {
  description = "Enable lifecycle rule for automatic object expiration and storage class transitions"
  type        = bool
  default     = false
}

variable "lifecycle_expiration_days" {
  description = "Number of days after which objects are permanently deleted"
  type        = number
  default     = 30
}

variable "lifecycle_transition_days" {
  description = "Number of days after which objects transition to lifecycle_storage_class. Must be less than lifecycle_expiration_days. Set to 0 to disable transition."
  type        = number
  default     = 0
}

variable "lifecycle_storage_class" {
  description = "Storage class to transition objects to (e.g. STANDARD_IA, GLACIER, DEEP_ARCHIVE)"
  type        = string
  default     = "STANDARD_IA"

  validation {
    condition = contains([
      "STANDARD_IA",
      "ONEZONE_IA",
      "INTELLIGENT_TIERING",
      "GLACIER",
      "DEEP_ARCHIVE",
      "GLACIER_IR"
    ], var.lifecycle_storage_class)
    error_message = "lifecycle_storage_class must be one of: STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, GLACIER_IR"
  }
}

# ================================================================
#  ACCESS LOGGING
# ================================================================

variable "enable_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = false
}

variable "log_bucket" {
  description = "Target S3 bucket name for access logs (required when enable_logging = true)"
  type        = string
  default     = ""
}

variable "log_prefix" {
  description = "Prefix for access log objects in the log bucket"
  type        = string
  default     = ""
}
