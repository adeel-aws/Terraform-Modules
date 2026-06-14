# 🚀 AWS CloudFront Module

![Terraform](https://img.shields.io/badge/Terraform-1.3+-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-CloudFront-FF9900?logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📌 Overview

Production-ready **AWS CloudFront Distribution** module supporting static websites, full-stack applications, and enterprise CDN setups.

Built-in support for:
- S3 static frontend with OAC (secure private access — no public bucket needed)
- Custom origins (ALB, API Gateway, EC2)
- SPA routing fallback (React, Vue, Angular)
- HTTPS via ACM
- Security response headers
- Optional WAF, logging, and geo restrictions

Designed to be reusable across all project types and environments.

---

## 🧠 Feature Map

| Feature | Variable | Default |
|---------|----------|---------|
| S3 OAC (private bucket) | `enable_oac` | `true` |
| SPA 404/403 fallback | `enable_spa_fallback` | `true` |
| Security headers (HSTS, XSS) | `enable_security_headers` | `false` |
| HTTPS custom domain | `domain_name` + `acm_certificate_arn` | `null` |
| WAF | `enable_waf` | `false` |
| Access logging | `enable_logging` | `false` |
| Geo restriction | `geo_restriction_type` | `none` |
| API cache bypass | `behaviors[].is_api = true` | automatic |
| Origin protocol | `origin_protocol_policy` | `http-only` |

---

## 📁 Module Structure

```
modules/CloudFront/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

---

## 🚀 Usage Examples

### 1. Static Website Only (S3)

Simplest setup — S3 frontend served through CloudFront with OAC.
No custom domain, no HTTPS certificate needed.

```hcl
module "cloudfront" {
  source = "../modules/CloudFront"

  project_name = "myapp"
  environment  = "dev"

  default_origin_id = "frontend"

  origins = [
    {
      id          = "frontend"
      domain_name = module.s3_frontend.bucket_domain_name
      type        = "s3"
      bucket_name = module.s3_frontend.bucket_name
      bucket_arn  = module.s3_frontend.bucket_arn
    }
  ]

  enable_oac          = true
  enable_spa_fallback = true
}
```

---

### 2. Full Stack — S3 Frontend + ALB Backend (No Custom Domain)

React frontend on S3 + Node.js/Express backend on ECS behind ALB.
API requests routed through CloudFront to ALB.

```hcl
module "cloudfront" {
  source = "../modules/CloudFront"

  project_name = "myapp"
  environment  = "dev"

  default_origin_id      = "frontend"
  origin_protocol_policy = "http-only"

  origins = [
    {
      id          = "frontend"
      domain_name = module.s3_frontend.bucket_domain_name
      type        = "s3"
      bucket_name = module.s3_frontend.bucket_name
      bucket_arn  = module.s3_frontend.bucket_arn
    },
    {
      id          = "api"
      domain_name = module.ecs.alb_dns_name
      type        = "custom"
    }
  ]

  behaviors = [
    {
      path_pattern     = "/api/*"
      target_origin_id = "api"
      is_api           = true
    }
  ]

  enable_oac              = true
  enable_spa_fallback     = true
  enable_security_headers = false
}
```

---

### 3. Production — Custom Domain + HTTPS + Security Headers

Full production setup with custom domain, ACM certificate, security headers.
ACM certificate must be in us-east-1 regardless of your AWS region.

```hcl
module "cloudfront" {
  source = "../modules/CloudFront"

  project_name = "myapp"
  environment  = "prod"

  default_origin_id      = "frontend"
  origin_protocol_policy = "https-only"

  origins = [
    {
      id          = "frontend"
      domain_name = module.s3_frontend.bucket_domain_name
      type        = "s3"
      bucket_name = module.s3_frontend.bucket_name
      bucket_arn  = module.s3_frontend.bucket_arn
    },
    {
      id          = "api"
      domain_name = module.ecs.alb_dns_name
      type        = "custom"
    }
  ]

  behaviors = [
    {
      path_pattern     = "/api/*"
      target_origin_id = "api"
      is_api           = true
    }
  ]

  domain_name         = "example.com"
  aliases             = ["app.example.com"]
  acm_certificate_arn = module.acm.certificate_arn

  enable_oac              = true
  enable_spa_fallback     = true
  enable_security_headers = true

  price_class = "PriceClass_100"

  tags = {
    Owner = "DevOps"
  }
}
```

---

## 🔐 OAC — How It Works

When `enable_oac = true`, the module:
1. Creates an Origin Access Control resource
2. Attaches it to all S3 origins
3. Creates an S3 bucket policy allowing only CloudFront to read objects

Your S3 bucket does **not** need to be public. This is the recommended AWS approach.

**Required inputs per S3 origin when OAC is enabled:**
```hcl
bucket_name = module.s3_frontend.bucket_name
bucket_arn  = module.s3_frontend.bucket_arn
```

---

## 🌐 Origin Protocol Policy

Controls how CloudFront connects to custom origins (ALB, EC2, API Gateway):

| Value | When to use |
|-------|-------------|
| `http-only` | ALB has no HTTPS (HTTP listener only) |
| `https-only` | ALB has HTTPS (ACM cert attached to ALB) |
| `match-viewer` | Pass through whatever the viewer uses |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `distribution_id` | CloudFront distribution ID (used for cache invalidation in CI/CD) |
| `distribution_domain_name` | CDN URL (e.g. d1234abc.cloudfront.net) |
| `distribution_arn` | Full ARN |
| `distribution_hosted_zone_id` | Hosted zone ID for Route53 alias records |

---

## 🧠 Notes

- ACM certificates for CloudFront **must** be created in `us-east-1`
- ALB certificates can be in any region matching your ALB
- `price_class = "PriceClass_100"` covers North America and Europe (cheapest)
- Security headers are disabled by default — enable for production
- API behaviors automatically disable caching and allow all HTTP methods

---

## 👨‍💻 Author

**Muhammad Adeel**  
DevOps Engineer
