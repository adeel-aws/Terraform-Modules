output "record_fqdns" {
  value = [for r in aws_route53_record.this : r.fqdn]
}