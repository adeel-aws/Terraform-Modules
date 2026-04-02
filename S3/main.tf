resource "aws_s3_bucket" "this" {
  bucket        = "${var.bucket_name}-${var.environment}"
  force_destroy = var.force_destroy
  tags          = var.tags
}
# Versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Block Public Access (controlled by variables)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Static website hosting
resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.enable_static_website ? 1 : 0
  bucket = aws_s3_bucket.this.id
  index_document { suffix = var.index_document }
  error_document { key = var.error_document }
}

# Bucket policy (fully independent)
resource "aws_s3_bucket_policy" "custom" {
  count  = var.attach_policy ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy
}

# Lifecycle rule
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.enable_lifecycle_rule ? 1 : 0
  bucket = aws_s3_bucket.this.id
  rule {
    id     = "auto-expire"
    status = "Enabled"
    expiration { days = var.lifecycle_expiration_days }
    dynamic "transition" {
      for_each = var.lifecycle_transition_days > 0 ? [1] : []
      content {
        days          = var.lifecycle_transition_days
        storage_class = var.lifecycle_storage_class
      }
    }
  }
}

# Logging
resource "aws_s3_bucket_logging" "this" {
  count         = var.enable_logging ? 1 : 0
  bucket        = aws_s3_bucket.this.id
  target_bucket = var.log_bucket
  target_prefix = var.log_prefix
}