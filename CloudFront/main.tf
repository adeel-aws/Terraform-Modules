locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------- OAC ----------------
resource "aws_cloudfront_origin_access_control" "this" {
  count = var.enable_oac ? 1 : 0

  name                              = "${local.name_prefix}-oac"
  description                       = "OAC for S3 origins"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ---------------- S3 Bucket Policy for OAC ----------------
resource "aws_s3_bucket_policy" "oac" {
  for_each = var.enable_oac ? {
    for o in var.origins : o.id => o if o.type == "s3"
  } : {}

  bucket = each.value.bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${each.value.bucket_arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
        }
      }
    }]
  })

  depends_on = [aws_cloudfront_distribution.this]
}

# ---------------- Cache Policies ----------------
data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

# ---------------- Response Headers Policy (Security Headers) ----------------
resource "aws_cloudfront_response_headers_policy" "security" {
  count = var.enable_security_headers ? 1 : 0

  name = "${local.name_prefix}-security-headers"

  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
  }
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
          origin_protocol_policy = var.origin_protocol_policy
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }

      dynamic "custom_header" {
        for_each = lookup(origin.value, "custom_headers", [])
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }
    }
  }

  # ---------------- Default Cache Behavior ----------------
  default_cache_behavior {
    target_origin_id       = var.default_origin_id
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress        = true
    cache_policy_id = var.cache_policy_id != null ? var.cache_policy_id : data.aws_cloudfront_cache_policy.optimized.id

    response_headers_policy_id = var.enable_security_headers ? aws_cloudfront_response_headers_policy.security[0].id : null
  }

  # ---------------- Ordered Behaviors (API / Static) ----------------
  dynamic "ordered_cache_behavior" {
    for_each = var.behaviors

    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      target_origin_id = ordered_cache_behavior.value.target_origin_id

      viewer_protocol_policy = "redirect-to-https"
      compress               = true

      allowed_methods = (
        ordered_cache_behavior.value.is_api
        ? ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        : ["GET", "HEAD"]
      )

      cached_methods = ["GET", "HEAD"]

      cache_policy_id = (
        ordered_cache_behavior.value.is_api
        ? data.aws_cloudfront_cache_policy.disabled.id
        : (var.cache_policy_id != null ? var.cache_policy_id : data.aws_cloudfront_cache_policy.optimized.id)
      )

      response_headers_policy_id = var.enable_security_headers ? aws_cloudfront_response_headers_policy.security[0].id : null
    }
  }

  # ---------------- SPA Fallback ----------------
  dynamic "custom_error_response" {
    for_each = var.enable_spa_fallback ? var.custom_error_responses : []

    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = 10
    }
  }

  # ---------------- Domain / Certificate ----------------
  aliases = var.domain_name != null ? concat([var.domain_name], var.aliases) : []

  viewer_certificate {
    cloudfront_default_certificate = var.domain_name == null

    acm_certificate_arn      = var.domain_name != null ? var.acm_certificate_arn : null
    ssl_support_method       = var.domain_name != null ? "sni-only" : null
    minimum_protocol_version = var.domain_name != null ? "TLSv1.2_2021" : "TLSv1"
  }

  # ---------------- WAF ----------------
  web_acl_id = var.enable_waf ? var.waf_web_acl_id : null

  # ---------------- Logging ----------------
  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      bucket          = var.logging_bucket_domain_name
      prefix          = "cloudfront/${local.name_prefix}/"
      include_cookies = false
    }
  }

  # ---------------- Geo Restriction ----------------
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
