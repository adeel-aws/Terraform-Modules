locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.bucket_name}"
}

# ================================================================
#  S3 BUCKET
# ================================================================

resource "aws_s3_bucket" "this" {
  bucket        = local.name_prefix
  force_destroy = var.force_destroy

  tags = merge(
    {
      Name        = local.name_prefix
      Project     = var.project_name
      Environment = var.environment
    },
    var.tags
  )
}

# ================================================================
#  VERSIONING
# ================================================================

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# ================================================================
#  ENCRYPTION (always on)
# ================================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ================================================================
#  PUBLIC ACCESS BLOCK (mode-driven)
#
#  private / cloudfront  → all blocks ON  (fully private)
#  public                → all blocks OFF (public read allowed)
# ================================================================

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.access_mode == "public" ? false : true
  block_public_policy     = var.access_mode == "public" ? false : true
  ignore_public_acls      = var.access_mode == "public" ? false : true
  restrict_public_buckets = var.access_mode == "public" ? false : true
}

# ================================================================
#  BUCKET POLICIES (mode-driven)
#
#  Only one policy is ever created — determined by access_mode.
#  Both depend on the access block being fully applied first.
# ================================================================

# PUBLIC MODE — open GetObject for everyone
resource "aws_s3_bucket_policy" "public" {
  count  = var.access_mode == "public" ? 1 : 0
  bucket = aws_s3_bucket.this.id

  depends_on = [aws_s3_bucket_public_access_block.this]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.this.arn}/*"
    }]
  })
}

# CLOUDFRONT MODE — OAC-based access
# AWS:SourceArn must be the CloudFront *distribution* ARN, not the OAC resource ARN.
# Reference: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
resource "aws_s3_bucket_policy" "cloudfront" {
  for_each = var.access_mode == "cloudfront" ? { "policy" = true } : {}
  bucket = aws_s3_bucket.this.id

  depends_on = [aws_s3_bucket_public_access_block.this]

  lifecycle {
    precondition {
      condition     = var.cloudfront_distribution_arn != null
      error_message = "cloudfront_distribution_arn must be provided when access_mode = cloudfront."
    }
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontOAC"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.this.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = var.cloudfront_distribution_arn
        }
      }
    }]
  })
}

# ================================================================
#  STATIC WEBSITE HOSTING (optional)
# ================================================================

resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.enable_static_website ? 1 : 0
  bucket = aws_s3_bucket.this.id

  index_document { suffix = var.index_document }
  error_document { key    = var.error_document }
}

# ================================================================
#  LIFECYCLE RULES (optional)
# ================================================================

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.enable_lifecycle_rule ? 1 : 0
  bucket = aws_s3_bucket.this.id

  lifecycle {
    precondition {
      condition = (
        var.lifecycle_transition_days == 0 ||
        var.lifecycle_transition_days < var.lifecycle_expiration_days
      )
      error_message = "lifecycle_transition_days (${var.lifecycle_transition_days}) must be less than lifecycle_expiration_days (${var.lifecycle_expiration_days})."
    }
  }

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

# ================================================================
#  ACCESS LOGGING (optional)
# ================================================================

resource "aws_s3_bucket_logging" "this" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.this.id

  lifecycle {
    precondition {
      condition     = var.log_bucket != ""
      error_message = "log_bucket must be set when enable_logging = true."
    }
  }

  target_bucket = var.log_bucket
  target_prefix = var.log_prefix
}
