locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------- OAC (Auto only if S3 exists) ----------------
resource "aws_cloudfront_origin_access_control" "this" {
  count = var.enable_oac ? 1 : 0

  name                              = "${local.name_prefix}-oac"
  description                       = "OAC for S3 origins"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ---------------- Cache Policy ----------------
data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

# ---------------- CloudFront Distribution ----------------
resource "aws_cloudfront_distribution" "this" {

  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.name_prefix}-distribution"

  default_root_object = var.default_root_object

  # ---------------- Origins ----------------
  dynamic "origin" {
    for_each = var.origins

    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.id

      # attach OAC only for S3 + enabled
      origin_access_control_id = (
        var.enable_oac && origin.value.type == "s3"
        ? aws_cloudfront_origin_access_control.this[0].id
        : null
      )

      dynamic "custom_origin_config" {
        for_each = origin.value.type == "custom" ? [1] : []
        content {
          http_port              = 80
          https_port             = 443
          origin_protocol_policy = "https-only"
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }

      # optional headers per origin
      dynamic "custom_header" {
        for_each = lookup(origin.value, "custom_headers", [])
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }
    }
  }

  # ---------------- Default Behavior ----------------
  default_cache_behavior {
    target_origin_id       = var.default_origin_id
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress        = true
    cache_policy_id = var.cache_policy_id
  }

  # ---------------- Route Behaviors (API / Static / etc) ----------------
  dynamic "ordered_cache_behavior" {
    for_each = var.behaviors

    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      target_origin_id = ordered_cache_behavior.value.target_origin_id

      viewer_protocol_policy = "redirect-to-https"
      compress               = true

      allowed_methods = (
        ordered_cache_behavior.value.is_api
        ? ["GET", "HEAD", "POST", "PUT", "DELETE", "PATCH"]
        : ["GET", "HEAD"]
      )

      cached_methods = ["GET", "HEAD"]

      cache_policy_id = (
        ordered_cache_behavior.value.is_api
        ? data.aws_cloudfront_cache_policy.disabled.id
        : var.cache_policy_id
      )
    }
  }

  # ---------------- SPA Support ----------------
  dynamic "custom_error_response" {
    for_each = var.enable_spa_fallback ? var.custom_error_responses : []

    content {
      error_code         = custom_error_response.value.error_code
      response_code      = custom_error_response.value.response_code
      response_page_path = custom_error_response.value.response_page_path
      error_caching_min_ttl = 10
    }
  }

  # ---------------- Domain ----------------
  aliases = var.domain_name != null ? [var.domain_name] : []

  viewer_certificate {
    cloudfront_default_certificate = var.domain_name == null

    acm_certificate_arn = var.domain_name != null ? var.acm_certificate_arn : null

    ssl_support_method       = var.domain_name != null ? "sni-only" : null
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # ---------------- WAF ----------------
  web_acl_id = var.enable_waf ? var.waf_web_acl_id : null

  # ---------------- Logging ----------------
  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []

    content {
      bucket = var.logging_bucket_domain_name
      prefix = "cloudfront/${local.name_prefix}/"
    }
  }

  # ---------------- Security Headers (future-safe optional hook) ----------------
  # (kept for extension via lambda@edge or response headers policy)

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  price_class = var.price_class

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-cf"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}