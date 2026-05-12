locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.bucket_name}"
}

resource "aws_s3_bucket" "this" {
  bucket        = local.name_prefix
  force_destroy = var.force_destroy

  tags = merge(
    { Name = local.name_prefix },
    var.tags
  )
}

# ----------------------------
# Versioning
# ----------------------------
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# ----------------------------
# Public Access Control (MODE BASED)
# ----------------------------
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.access_mode == "public" ? false : true
  block_public_policy     = var.access_mode == "public" ? false : true
  ignore_public_acls      = var.access_mode == "public" ? false : true
  restrict_public_buckets = var.access_mode == "public" ? false : true
}

# ----------------------------
# Static Website Hosting
# ----------------------------
resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.enable_static_website ? 1 : 0
  bucket = aws_s3_bucket.this.id

  index_document { suffix = var.index_document }
  error_document { key    = var.error_document }
}

# ----------------------------
# Security Policy (MODE BASED)
# ----------------------------

# PUBLIC MODE
resource "aws_s3_bucket_policy" "public" {
  count  = var.access_mode == "public" ? 1 : 0
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.this.arn}/*"
    }]
  })
}

# CLOUDFRONT MODE (OAC READY)
resource "aws_s3_bucket_policy" "cloudfront" {
  count  = var.access_mode == "cloudfront" && var.cloudfront_oac_arn != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.this.arn}/*"

      Condition = {
        StringEquals = {
          "AWS:SourceArn" = var.cloudfront_oac_arn
        }
      }
    }]
  })
}

# ----------------------------
# Encryption (BEST PRACTICE)
# ----------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ----------------------------
# Lifecycle
# ----------------------------
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.enable_lifecycle_rule ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "auto-cleanup"
    status = "Enabled"

    expiration {
      days = var.lifecycle_expiration_days
    }

    dynamic "transition" {
      for_each = var.lifecycle_transition_days > 0 ? [1] : []
      content {
        days          = var.lifecycle_transition_days
        storage_class = var.lifecycle_storage_class
      }
    }
  }
}

# ----------------------------
# Logging
# ----------------------------
resource "aws_s3_bucket_logging" "this" {
  count         = var.enable_logging ? 1 : 0
  bucket        = aws_s3_bucket.this.id
  target_bucket = var.log_bucket
  target_prefix = var.log_prefix
}