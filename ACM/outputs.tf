output "certificate_arn" {
  description = "ACM Certificate ARN"
  value       = aws_acm_certificate.this.arn
}

output "certificate_domain_name" {
  description = "Certificate domain name"
  value       = aws_acm_certificate.this.domain_name
}

# ---------------------------------------------------------
# Use this output to manually add validation records
# to GoDaddy, Cloudflare, Namecheap, or Route53
# when auto_validate_via_route53 = false
# ---------------------------------------------------------
output "validation_records" {
  description = "DNS validation records to add manually when auto_validate_via_route53 = false"
  value = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

output "validation_record_fqdns" {
  description = "Validation record FQDNs — available when auto_validate_via_route53 = true"
  value = [
    for record in aws_route53_record.validation : record.fqdn
  ]
}