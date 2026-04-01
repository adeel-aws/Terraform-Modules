# S3 Module

This module creates an **AWS S3 bucket** with optional versioning, server-side encryption, and public access block. It is reusable for any Terraform project.

---

## 🛠️ Required Inputs

| Name          | Description                    | Type   | Required |
|---------------|--------------------------------|--------|----------|
| `bucket_name` | Name of the S3 bucket           | string | yes      |

---

## ⚙️ Optional Inputs

| Name               | Description                                      | Type   | Default |
|--------------------|--------------------------------------------------|--------|---------|
| `enable_versioning` | Enable S3 bucket versioning                     | bool   | true    |
| `force_destroy`     | Delete bucket even if not empty                 | bool   | false   |
| `tags`              | Map of tags to apply to the bucket             | map(string) | {} |

---

## 📤 Outputs

| Name          | Description                        |
|---------------|------------------------------------|
| `bucket_name` | Name of the created S3 bucket       |
| `bucket_arn`  | ARN of the created S3 bucket        |

---

## 🔧 Example Usage

```hcl
module "s3_bucket" {
  source = "./modules/s3"

  bucket_name       = "adeel-devops-bucket-123"
  enable_versioning = true
  force_destroy     = false

  tags = {
    Environment = "dev"
    Project     = "learning"
  }
}