# 🚀 AWS CloudFront Module

![Terraform](https://img.shields.io/badge/Terraform-1.3+-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-CloudFront-FF9900?logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📌 Overview

This module provisions a production-ready **AWS CloudFront Distribution** for modern multi-origin applications.

It supports:
- Static websites (S3)
- Backend APIs (ALB / ECS / EC2)
- SPA applications
- Secure edge delivery
- Optional HTTPS, WAF, logging, and geo restrictions

Designed to be **fully reusable across projects (DevOps → CI/CD → Kubernetes frontend routing)**.

---

## 🧠 Feature Map (What this module supports)

### 🌍 Origin Types
- S3 (static frontend)
- Custom origin (ALB / API Gateway / EC2)

### 🚀 Routing
- Default origin routing
- Path-based routing (`/api/*`, `/admin/*`, etc.)
- Multi-service edge routing

### 🔐 Security
- Origin Access Control (OAC) for S3
- HTTPS with ACM certificate
- Optional AWS WAF integration
- Custom headers support

### ⚡ Performance
- CloudFront caching policies
- API cache bypass support
- Compression enabled

### 🧾 SPA Support
- 403 / 404 → `/index.html` fallback

### 📊 Observability
- CloudFront access logging (optional)
- Geo restriction support

---

## 📥 Input Contract (IMPORTANT)

### Required Inputs
```hcl
project_name
environment
origins
default_origin_id
```

---

### Optional Common Inputs
```hcl
behaviors
domain_name
acm_certificate_arn
enable_logging
logging_bucket_domain_name
enable_waf
tags
```

---

### Feature Enablement Map

| Feature | Input |
|--------|------|
| Static website | S3 origin only |
| API routing | behaviors + custom origin |
| HTTPS | domain_name + acm_certificate_arn |
| Logging | enable_logging = true |
| WAF | enable_waf = true |
| SPA support | automatic (built-in) |

---

## 📁 Module Structure

```text
modules/cloudfront/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

---

## 🚀 Usage Templates

### 🟢 1. Static Website (S3 Only)

```hcl
module "cloudfront" {
  source = "./modules/cloudfront"

  project_name = "portal"
  environment  = "dev"

  default_origin_id = "frontend"

  origins = [
    {
      id          = "frontend"
      domain_name = module.s3.bucket_domain_name
      type        = "s3"
    }
  ]
}
```

---

### 🔵 2. Full Stack (S3 + API)

```hcl
module "cloudfront" {
  source = "./modules/cloudfront"

  project_name = "myapp"
  environment  = "dev"

  default_origin_id = "frontend"

  origins = [
    {
      id          = "frontend"
      domain_name = module.s3.bucket_domain_name
      type        = "s3"
    },
    {
      id          = "api"
      domain_name = module.alb.dns_name
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
}
```

---

### 🔴 3. Production Setup (HTTPS + Logging + WAF)

```hcl
module "cloudfront" {
  source = "./modules/cloudfront"

  project_name = "myapp"
  environment  = "prod"

  default_origin_id = "frontend"

  origins = [
    {
      id          = "frontend"
      domain_name = module.s3.bucket_domain_name
      type        = "s3"
    },
    {
      id          = "api"
      domain_name = module.alb.dns_name
      type        = "custom"
    }
  ]

  domain_name         = "app.mycompany.com"
  acm_certificate_arn = "arn:aws:acm:region:account:cert/xxx"

  enable_logging = true
  logging_bucket_domain_name = module.logs.bucket_domain_name

  enable_waf = false

  tags = {
    Owner = "DevOps"
    Project = "Platform"
  }
}
```

---

## ⚙️ Notes

- S3 origins automatically use OAC (secure private access)
- API caching is disabled automatically via behavior flag
- HTTPS is enforced when domain + ACM is provided
- Module is environment-agnostic (dev/staging/prod)

---

## 📤 Outputs

| Output | Description |
|------|-------------|
| distribution_id | CloudFront ID |
| distribution_domain_name | CDN URL |
| distribution_arn | ARN |

---

## 🧠 Design Philosophy

- Everything optional
- No forced architecture
- Works for static → full-stack → enterprise systems
- Consistent naming across all modules (ECS, RDS, CloudFront)

---

## 👨‍💻 Author

Muhammad Adeel  :  
DevOps Engineer