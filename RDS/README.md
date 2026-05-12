# 🗄️ AWS RDS Module

![Terraform](https://img.shields.io/badge/Terraform-1.3+-623CE4?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/RDS-Database-527FFF?logo=amazonaws&logoColor=white)

## 📌 Overview
This module provisions a highly secure, private-network **AWS RDS Instance**. It supports storage autoscaling, Multi-AZ deployments for high availability, and automatic integration with AWS Systems Manager (SSM) for endpoint discovery.

## ✨ Key Features
- ✅ **Network Isolated:** Enforced `publicly_accessible = false` to keep your data off the internet.
- ✅ **Storage Autoscaling:** Uses `max_allocated_storage` to handle unexpected data growth.
- ✅ **SSM Integration:** Automatically stores the DB endpoint in SSM Parameter Store for easy consumption by ECS/EC2.
- ✅ **Security Hardened:** Storage encryption enabled by default.
- ✅ **Multi-AZ Support:** Simple toggle for production-ready failover capability.

---

## 🚀 Complete Usage Template

```hcl
module "rds" {
  source = "./modules/rds"

  project_name = var.project_name
  environment  = var.environment

  subnet_ids = module.vpc.private_subnet_ids
  sg_ids     = module.vpc.db_sg_ids

  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "appdb"
  username = "admin"
  password = var.db_password
  port     = 3306

  multi_az            = true
  backup_retention    = 7
  deletion_protection = false

  enable_ssm_parameters = true
}