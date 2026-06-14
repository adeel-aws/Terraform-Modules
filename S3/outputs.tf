output "bucket_name" {
  description = "S3 bucket name (also the bucket ID)"
  value       = aws_s3_bucket.this.id
}

output "bucket_id" {
  description = "S3 bucket ID (same as bucket name — explicit alias for module consumers)"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "S3 regional REST endpoint — use this as CloudFront OAC origin domain (not the website endpoint)"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "website_endpoint" {
  description = "S3 static website endpoint URL (only populated when enable_static_website = true)"
  value       = try(aws_s3_bucket_website_configuration.this[0].website_endpoint, "")
}

output "bucket_region" {
  description = "AWS region the bucket was created in"
  value       = aws_s3_bucket.this.region
}
