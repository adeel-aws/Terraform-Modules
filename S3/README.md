# S3 Module

Professional, reusable Terraform module to create an AWS S3 bucket with **independent optional features**.

---

## Features

- Default bucket like AWS console
- Optional:
  - Public access
  - Static website hosting
  - Bucket policy (public or custom)
  - Versioning
  - Lifecycle with expiration & storage class
  - Logging

---

## Required Inputs

| Name        | Type   |
|-------------|--------|
| bucket_name | string |

---

## Optional Inputs

| Name                     | Type   | Default |
|---------------------------|--------|---------|
| environment               | string | dev     |
| enable_versioning         | bool   | false   |
| force_destroy             | bool   | false   |
| tags                      | map    | {}      |
| allow_public_access       | bool   | false   |
| block_public_acls         | bool   | true    |
| block_public_policy       | bool   | true    |
| ignore_public_acls        | bool   | true    |
| restrict_public_buckets   | bool   | true    |
| enable_static_website     | bool   | false   |
| index_document            | string | index.html |
| error_document            | string | error.html |
| attach_policy             | bool   | false   |
| bucket_policy             | string | ""      |
| enable_lifecycle_rule     | bool   | false   |
| lifecycle_expiration_days | number | 30      |
| lifecycle_transition_days | number | 0       |
| lifecycle_storage_class   | string | STANDARD_IA |
| enable_logging            | bool   | false   |
| log_bucket                | string | ""      |
| log_prefix                | string | ""      |

---

## Example Usage

```hcl
# ----------------------------
# Example 1: Plain Private Bucket (Default)
# ----------------------------
module "s3_bucket" {
  source      = "./modules/s3"
  bucket_name = "myapp-dev"
  environment = "dev"
}

# ----------------------------
# Example 2: Static Website Hosting
# ----------------------------
module "s3_bucket_website" {
  source = "./modules/s3"

  bucket_name           = "myapp-prod"
  environment           = "prod"
  allow_public_access   = true
  enable_static_website = true
  attach_policy         = true

  index_document = "index.html"
  error_document = "error.html"

  enable_lifecycle_rule     = true
  lifecycle_expiration_days = 60
  lifecycle_transition_days = 30
  lifecycle_storage_class   = "STANDARD_IA"

  enable_logging = true
  log_bucket     = "myapp-logs"
  log_prefix     = "prod/"

  bucket_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::myapp-prod/*"
    }
  ]
}
EOF
}