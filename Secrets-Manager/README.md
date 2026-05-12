# 🔐 AWS Secrets Manager Terraform Module

## 📌 Overview

A specialized utility module designed to securely store and manage application credentials. It is optimized for use with ECS Fargate, allowing for seamless injection of sensitive data into container environments.

## ✨ Features

- **JSON Mapping:** Uses `secret_map` to store multiple key-value pairs (e.g., username/password) in a single secret.
- **Safe Lifecycle:** Configurable recovery window to prevent accidental permanent deletion.
- **ECS Integration:** Designed to provide the `secret_arn` required for ECS Execution Role IAM policies.
- **Standardized Naming:** Automatically names secrets based on project and environment inputs.

## 🛠️ Module Structure

- `main.tf`: Manages the secret container and the versioning (string/JSON).
- `variables.tf`: Accepts a map of strings for flexible data storage.
- `outputs.tf`: Returns the ARN and Name for resource linking.

## 🚀 Example Usage

```hcl
module "db_secret" {
  source = "./modules/secrets-manager"

  project_name = var.project_name
  environment  = var.environment

  name        = "db-credentials"
  description = "Database credentials for backend service"

  secret_map = {
    username = var.db_username
    password = var.db_password
  }

  recovery_window_in_days = 7
}