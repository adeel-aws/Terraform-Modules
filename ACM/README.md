# 🚀 Terraform ACM Module

## 📌 Overview

Production-ready reusable ACM module with:

- DNS validation
- Optional Route53 automatic validation
- Manual validation support (GoDaddy, Cloudflare, Namecheap)
- SAN support
- Zero downtime replacement
- Compatible with:
  - ALB
  - NLB
  - CloudFront
  - API Gateway

---

## 📁 Structure

```text
ACM/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

---

## 📦 Resources Created

| Resource | Purpose |
|---|---|
| aws_acm_certificate | Creates SSL certificate |
| aws_route53_record | DNS validation records (optional) |
| aws_acm_certificate_validation | Certificate validation (optional) |

---

## 📥 Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| project_name | string | Yes | Project name |
| environment | string | Yes | Environment |
| domain_name | string | Yes | Primary domain |
| subject_alternative_names | list(string) | No | SAN domains |
| auto_validate_via_route53 | bool | No | Auto create Route53 validation records (default: false) |
| hosted_zone_id | string | No | Required only when auto_validate_via_route53 = true |
| tags | map(string) | No | Resource tags |

---

## 📤 Outputs

| Name | Description |
|---|---|
| certificate_arn | ACM Certificate ARN |
| certificate_domain_name | Primary domain name |
| validation_records | CNAME records for manual DNS validation |
| validation_record_fqdns | FQDNs when auto Route53 validation is used |

---

## 🚀 Example Usage

### Manual Validation (GoDaddy / Cloudflare / Namecheap)

```hcl
module "acm" {
  source = "./modules/acm"

  project_name = "signoz"
  environment  = "prod"

  domain_name = "monitoring.example.com"

  subject_alternative_names = [
    "*.example.com"
  ]

  tags = {
    Project     = "signoz"
    Environment = "prod"
  }
}
```

After apply, copy `validation_records` output and manually add the CNAME records in your DNS provider. Certificate will become active once DNS propagates.

---

### Auto Validation via Route53

```hcl
module "acm" {
  source = "./modules/acm"

  project_name = "signoz"
  environment  = "prod"

  domain_name = "monitoring.example.com"

  subject_alternative_names = [
    "*.example.com"
  ]

  auto_validate_via_route53 = true
  hosted_zone_id            = "ZXXXXXXXXXXXX"

  # or reference from route53 module:
  # hosted_zone_id = module.route53.zone_id

  tags = {
    Project     = "signoz"
    Environment = "prod"
  }
}
```

---

### Reference ACM in ELB Module

```hcl
module "elb" {
  source = "./modules/elb"

  certificate_arn = module.acm.certificate_arn
}
```

---

## ✅ Features

| Feature | Status |
|---|---|
| Manual DNS validation | ✅ |
| Auto Route53 validation | ✅ |
| Wildcard certificates | ✅ |
| SAN support | ✅ |
| Zero downtime replacement | ✅ |
| No forced Route53 dependency | ✅ |
| Reusable across projects | ✅ |

---

## 🏷 Naming Convention

```text
signoz-prod-acm
```

---

## 🔒 Notes

- When `auto_validate_via_route53 = false` — certificate is created in `PENDING_VALIDATION`. Copy `validation_records` output and add CNAMEs manually in your DNS provider.
- When `auto_validate_via_route53 = true` — `hosted_zone_id` is required. Module handles everything automatically.
- `certificate_arn` is always available regardless of validation method — use it in ELB, CloudFront, API Gateway.