locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = var.subject_alternative_names

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-acm"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------
# OPTIONAL - Auto validate via Route53
# ---------------------------------------------------------
resource "aws_route53_record" "validation" {
  for_each = var.auto_validate_via_route53 ? {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60

  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "this" {
  count = var.auto_validate_via_route53 ? 1 : 0

  certificate_arn = aws_acm_certificate.this.arn

  validation_record_fqdns = [
    for record in aws_route53_record.validation : record.fqdn
  ]

  depends_on = [
    aws_route53_record.validation
  ]
}