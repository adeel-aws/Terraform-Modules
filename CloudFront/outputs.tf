output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name (e.g. d1234abc.cloudfront.net)"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_hosted_zone_id" {
  description = "CloudFront hosted zone ID (used for Route53 alias records)"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}
