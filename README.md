# 🏗️ Terraform AWS Modules — Production-Ready Infrastructure Library

> A battle-tested collection of reusable Terraform modules for provisioning AWS infrastructure — built for speed, consistency, and production confidence.

![Terraform](https://img.shields.io/badge/Terraform-1.3+-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Modules-FF9900?logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green)
![Modules](https://img.shields.io/badge/Modules-8-blue)

---

## 📌 What Is This?

This repository is a **central Terraform module registry** — each folder is a self-contained, independently usable module that follows AWS best practices and DevOps standards.

Instead of rewriting infrastructure from scratch for every project, these modules let you **spin up production-grade AWS resources in minutes** with clean, consistent configuration.

---

## 📦 Available Modules

### 🌐 VPC
Provision a fully customizable Virtual Private Cloud with subnets, routing, and gateway support.

### 🪣 S3
Create secure S3 buckets with optional versioning, lifecycle rules, static hosting, policies, and logging.

### 🖥️ EC2
Launch EC2 instances with AMI, key pair, security groups, user data, SSM access, and Elastic IP support.

### 📦 ECR
Provision Elastic Container Registry repositories with encryption, image scanning, and lifecycle policies.

### 🚀 ECS
Deploy containerized workloads on ECS Fargate with task definitions, services, and IAM roles.

### 🗄️ RDS
Provision relational databases with parameter groups, subnet groups, encryption, and backup configuration.

### 🔐 Secrets Manager
Manage secrets securely with rotation support, KMS encryption, and resource-based policies.

### 🌍 CloudFront
Set up CDN distributions with custom origins, cache behaviors, SSL certificates, and geo-restrictions.

---

## 📁 Repository Structure

```
modules/
│
├── VPC/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── S3/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── EC2/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── ECR/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── ECS/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── RDS/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── Secrets-Manager/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── CloudFront/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
└── README.md   ← you are here
```

---

## ⚙️ How to Use

**1. Clone the repository:**

```bash
git clone https://github.com/adeel-aws/Terraform-Modules.git
```

**2. Call any module from your root configuration:**

```hcl
module "vpc" {
  source = "./VPC"

  project_name = "myapp"
  environment  = "prod"
}

module "ec2" {
  source = "./EC2"

  ami_id        = "ami-0123456789abcdef0"
  instance_type = "t3.medium"
  subnet_id     = module.vpc.public_subnet_ids[0]
}
```

**3. Initialize and apply:**

```bash
terraform init
terraform plan
terraform apply
```

---

## 📘 Module Documentation

Every module contains its own **README.md** covering:

- ✅ Features & capabilities
- ✅ Required & optional input variables
- ✅ Output values
- ✅ Example usage
- ✅ Design decisions & notes

👉 Open any module folder above to get full details.

---

## 💡 Design Principles

| Principle | Description |
|-----------|-------------|
| 🔁 Reusable | Each module works independently across any project |
| 🔓 Loosely coupled | Features are optional — enable only what you need |
| 🏷️ Consistent naming | All resources follow `project-environment-resource` convention |
| 🔒 Secure by default | Encryption, IAM, and access controls built in |
| 📦 Self-documented | Every module ships with its own README |

---

## 🎯 Goal

- Eliminate infrastructure boilerplate across projects
- Enforce consistent AWS resource standards
- Accelerate deployment from hours to minutes
- Follow real-world DevOps and IaC best practices

---

## 📜 License

This project is open-source and available under the MIT License.

---

## 👨‍💻 Author

**Muhammad Adeel**  :  
(DevOps Engineer)
