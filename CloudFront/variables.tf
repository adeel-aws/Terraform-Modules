variable "project_name" { type = string }
variable "environment"  { type = string }

# ---------------- FEATURE FLAGS ----------------
variable "enable_oac" {
  type    = bool
  default = true
}

variable "enable_waf" {
  type    = bool
  default = false
}

variable "enable_logging" {
  type    = bool
  default = false
}

variable "enable_spa_fallback" {
  type    = bool
  default = true
}

# ---------------- ORIGINS ----------------
variable "origins" {
  type = list(object({
    id          = string
    domain_name = string
    type        = string # s3 | custom

    custom_headers = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
}

variable "default_origin_id" { type = string }

variable "default_root_object" {
  type    = string
  default = "index.html"
}

# ---------------- BEHAVIORS ----------------
variable "behaviors" {
  type = list(object({
    path_pattern     = string
    target_origin_id = string
    is_api           = bool
  }))
  default = []
}

# ---------------- CACHE ----------------
variable "cache_policy_id" {
  type    = string
  default = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

# ---------------- SPA ERROR ----------------
variable "custom_error_responses" {
  type = list(object({
    error_code         = number
    response_code      = number
    response_page_path = string
  }))

  default = [
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    },
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    }
  ]
}

# ---------------- DOMAIN ----------------
variable "domain_name" {
  type    = string
  default = null
}

variable "acm_certificate_arn" {
  type    = string
  default = null
}

# ---------------- WAF ----------------
variable "waf_web_acl_id" {
  type    = string
  default = null
}

# ---------------- LOGGING ----------------
variable "logging_bucket_domain_name" {
  type    = string
  default = null
}

# ---------------- RESTRICTIONS ----------------
variable "geo_restriction_type" {
  type    = string
  default = "none"
}

variable "geo_restriction_locations" {
  type    = list(string)
  default = []
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "tags" {
  type    = map(string)
  default = {}
}