# 🚀 AWS EC2 Instance Module

![Terraform](https://img.shields.io/badge/Terraform-1.3+-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📌 Overview

This module provisions a **production-ready AWS EC2 instance** with flexible configuration for DevOps, CI/CD, bastion hosts, and application servers.

It is designed to stay **simple by default but enterprise-ready when needed**.

---

## 🏗️ Architecture Features

- Flexible EC2 provisioning (AMI, instance type, subnet, SGs)
- Optional **SSM access (no SSH required)**
- Optional **Elastic IP (EIP) support**
- User data bootstrap support
- Multi-security-group attachment
- Environment-based naming convention
- Safe production defaults (non-breaking design)

---

## 📁 Module Structure

```
modules/ec2/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

---

## 🚀 Example Usage

```hcl
module "app_server" {
  source = "./modules/ec2"

  project_name = "platform"
  environment  = "prod"

  instance_name = "app-node-01"
  ami_id        = "ami-0123456789abcdef0"
  instance_type = "t3.medium"

  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.vpc.app_sg_id]

  key_name = "my-keypair"

  # Secure access without SSH
  enable_ssm = true

  # Optional static public access
  enable_eip = true

  # Storage configuration
  root_volume_size         = 50
  root_volume_type         = "gp3"
  enable_volume_encryption = true

  # Monitoring
  enable_detailed_monitoring = true

   # Bootstrapping
  user_data = file("install.sh")

  tags = {
    Owner = "DevOps-Team"
    Service = "Backend"
  }
}
```

---

## ⚙️ Input Variables

### 🔴 Required

| Name   | Description     | Type   |
|--------|----------------|--------|
| ami_id | AMI ID for EC2 | string |

---

### 🟡 Optional

| Name               | Description                 | Type         | Default     |
|--------------------|-----------------------------|-------------|-------------|
| instance_name      | EC2 instance name          | string       | web-server  |
| instance_type      | EC2 type                   | string       | t3.micro    |
| subnet_id          | Subnet ID                  | string       | null        |
| security_group_ids | Security groups            | list(string) | []          |
| key_name           | SSH key pair               | string       | ""          |
| user_data          | Bootstrap script           | string       | ""          |
| enable_ssm         | Enable SSM access          | bool         | false       |
| enable_eip         | Attach Elastic IP          | bool         | false       |
| environment        | Environment name           | string       | dev         |

---

## 🔐 Security Design

- SSM-based access (recommended over SSH)
- Security-group controlled network access
- Supports private subnet deployment
- Optional public IP / EIP usage
- Works with IAM roles if extended later

---

## 📊 Use Cases

- CI/CD runner instances
- Bastion hosts (SSM-based)
- Application servers (Node, Laravel, Python, etc.)
- Debug / testing environments
- Internal tooling servers

---

## 📤 Outputs

| Output       | Description       |
|-------------|------------------|
| instance_id | EC2 instance ID   |
| public_ip   | Public IP         |
| private_ip  | Private IP        |

---

## 🧠 Design Philosophy

- Simple by default
- Enterprise-ready when needed
- No forced features
- Safe for production use
- Fully reusable across environments

---

## 👨‍💻 Author

Muhammad Adeel  :  
(DevOps Engineer)
