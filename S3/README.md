# 🚀 AWS S3 Module (Production Ready)

![Terraform](https://img.shields.io/badge/Terraform-1.3+-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-S3-FF9900?logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📌 Overview

This Terraform module provisions a **highly reusable AWS S3 bucket** with support for multiple operating modes:

* Private storage (default)
* Public static hosting
* CloudFront-secured storage (OAC-ready)

Designed using **Terraform Registry standards + DevOps best practices**, making it suitable for:

* CI/CD pipelines
* Multi-environment setups (dev/staging/prod)
* CloudFront + frontend architectures

---

## 🧠 Operating Modes (Core Design)

| Mode         | Description                                        |
| ------------ | -------------------------------------------------- |
| `private`    | Secure bucket (no public access)                   |
| `public`     | Public S3 access enabled                           |
| `cloudfront` | Locked bucket accessible only via CloudFront (OAC) |

---

## 🚀 Features

### 📦 Storage

* S3 bucket creation with standardized naming
* Environment-based isolation
* Force destroy option for dev

### 🔐 Security

* Block public access controls
* CloudFront OAC support
* AES256 encryption enabled by default

### 🌐 Static Hosting

* Optional S3 website hosting
* Index and error document support

### 🔁 Versioning

* Enable/disable object versioning

### 🧹 Lifecycle Management

* Expiration rules
* Storage class transitions

### 📊 Logging

* Optional access logging support

---

## 📥 Inputs

### Required Inputs

| Name        | Type   | Description      |
| ----------- | ------ | ---------------- |
| bucket_name | string | Base bucket name |

---

### Core Configuration

| Name         | Type   | Default | Description                   |
| ------------ | ------ | ------- | ----------------------------- |
| project_name | string | myapp   | Project identifier            |
| environment  | string | dev     | Environment name              |
| access_mode  | string | private | private / public / cloudfront |

---

### Feature Flags

| Name                  | Type | Default |
| --------------------- | ---- | ------- |
| enable_static_website | bool | false   |
| enable_versioning     | bool | false   |
| enable_lifecycle_rule | bool | false   |
| enable_logging        | bool | false   |
| force_destroy         | bool | false   |

---

### Lifecycle Settings

| Name                      | Type   | Default     |
| ------------------------- | ------ | ----------- |
| lifecycle_expiration_days | number | 30          |
| lifecycle_transition_days | number | 0           |
| lifecycle_storage_class   | string | STANDARD_IA |

---

### Logging

| Name       | Type   | Default |
| ---------- | ------ | ------- |
| log_bucket | string | ""      |
| log_prefix | string | ""      |

---

### CloudFront Support

| Name               | Type   | Default |
| ------------------ | ------ | ------- |
| cloudfront_oac_arn | string | null    |

---

## 🚀 Usage Examples

---

### 🟢 1. Private Bucket (Default)

```hcl
module "s3" {
  source = "./modules/s3"

  bucket_name  = "app"
  project_name = "myapp"
  environment  = "dev"
}
```

---

### 🌐 2. Public Static Website

```hcl
module "s3" {
  source = "./modules/s3"

  bucket_name           = "frontend"
  project_name          = "myapp"
  environment           = "dev"

  access_mode           = "public"
  enable_static_website = true
}
```

---

### 🔵 3. CloudFront Secure Mode (Production)

```hcl
module "s3" {
  source = "./modules/s3"

  bucket_name  = "frontend"
  project_name = "myapp"
  environment  = "prod"

  access_mode          = "cloudfront"
  cloudfront_oac_arn   = module.cloudfront.distribution_arn
}
```

---

### ⚙️ 4. Production Setup

```hcl
module "s3" {
  source = "./modules/s3"

  bucket_name           = "app"
  project_name          = "myapp"
  environment           = "prod"

  access_mode           = "cloudfront"
  enable_versioning     = true
  enable_logging        = true
  enable_lifecycle_rule = true

  cloudfront_oac_arn    = module.cloudfront.distribution_arn
}
```

---

## 📤 Outputs

| Output             | Description                 |
| ------------------ | --------------------------- |
| bucket_name        | S3 bucket name              |
| bucket_arn         | S3 bucket ARN               |
| website_endpoint   | S3 website URL (if enabled) |
| bucket_domain_name | Regional domain name        |

---

## 🧠 Design Principles

* Single responsibility (S3 only)
* Mode-based architecture (no boolean chaos)
* CloudFront-ready but independent
* Secure-by-default (private mode)
* CI/CD friendly and reusable

---

## 🚀 Best Practices

* Use `access_mode = cloudfront` for production
* Avoid public mode in production
* Enable versioning for critical workloads
* Use lifecycle rules to reduce cost
* Always pair with CloudFront in production setups

---

## 🔥 Future Enhancements

* CloudFront module integration automation
* Multi-region replication support
* Advanced CORS policy presets
* WAF integration via CloudFront

---

## 👨‍💻 Author

Muhammad Adeel
DevOps Engineer
