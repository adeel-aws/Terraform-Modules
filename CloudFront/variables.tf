variable "project_name" { type = string }
variable "environment"  { type = string }

# ---------------- FEATURE FLAGS ----------------
variable "enable_oac" {
  description = "Enable Origin Access Control for S3 origins (recommended)"
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Attach an AWS WAF Web ACL to the distribution"
  type        = bool
  default     = false
}

variable "enable_logging" {
  description = "Enable CloudFront access logging to an S3 bucket"
  type        = bool
  default     = false
}

variable "enable_spa_fallback" {
  description = "Redirect 403/404 errors to index.html for SPA routing"
  type        = bool
  default     = true
}

variable "enable_security_headers" {
  description = "Attach a response headers policy with HSTS, XSS, and frame protection"
  type        = bool
  default     = false
}

# ---------------- ORIGINS ----------------
variable "origins" {
  description = "List of origins (S3 or custom ALB/API)"
  type = list(object({
    id          = string
    domain_name = string
    type        = string # "s3" | "custom"

    # Required only when enable_oac = true and type = "s3"
    bucket_name = optional(string, null)
    bucket_arn  = optional(string, null)

    custom_headers = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
}

variable "default_origin_id" {
  description = "Origin ID to use for the default cache behavior"
  type        = string
}

variable "default_root_object" {
  description = "Default root object served by CloudFront"
  type        = string
  default     = "index.html"
}

# ---------------- BEHAVIORS ----------------
variable "behaviors" {
  description = "Ordered cache behaviors for path-based routing (e.g. /api/*)"
  type = list(object({
    path_pattern     = string
    target_origin_id = string
    is_api           = bool
  }))
  default = []
}

# ---------------- CACHE ----------------
variable "cache_policy_id" {
  description = "CloudFront cache policy ID. Defaults to Managed-CachingOptimized if null"
  type        = string
  default     = null
}

# ---------------- ORIGIN PROTOCOL ----------------
variable "origin_protocol_policy" {
  description = "Protocol for CloudFront to use when connecting to custom origins. Use http-only or https-only"
  type        = string
  default     = "http-only"

  validation {
    condition     = contains(["http-only", "https-only", "match-viewer"], var.origin_protocol_policy)
    error_message = "origin_protocol_policy must be http-only, https-only, or match-viewer."
  }
}

# ---------------- SPA ERROR RESPONSES ----------------
variable "custom_error_responses" {
  description = "Custom error responses for SPA fallback"
  type = list(object({
    error_code         = number
    response_code      = number
    response_page_path = string
  }))
  default = [
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    },
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    }
  ]
}

# ---------------- DOMAIN / HTTPS ----------------
variable "domain_name" {
  description = "Custom domain alias for CloudFront (e.g. app.example.com). Requires acm_certificate_arn"
  type        = string
  default     = null
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS. Must be in us-east-1"
  type        = string
  default     = null
}

variable "aliases" {
  description = "Additional domain aliases for CloudFront (e.g. www.example.com). domain_name is always included automatically."
  type        = list(string)
  default     = []
}

# ---------------- WAF ----------------
variable "waf_web_acl_id" {
  description = "ARN of AWS WAF Web ACL to attach"
  type        = string
  default     = null
}

# ---------------- LOGGING ----------------
variable "logging_bucket_domain_name" {
  description = "S3 bucket domain name for CloudFront access logs (e.g. my-logs.s3.amazonaws.com)"
  type        = string
  default     = null
}

# ---------------- GEO RESTRICTION ----------------
variable "geo_restriction_type" {
  description = "Geo restriction type: none, whitelist, or blacklist"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "geo_restriction_type must be none, whitelist, or blacklist."
  }
}

variable "geo_restriction_locations" {
  description = "ISO 3166 country codes for geo restriction"
  type        = list(string)
  default     = []
}

# ---------------- PERFORMANCE ----------------
variable "price_class" {
  description = "CloudFront price class: PriceClass_100 (NA/EU), PriceClass_200, PriceClass_All"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "tags" {
  description = "Additional tags to merge onto all resources"
  type        = map(string)
  default     = {}
}
