# 🚀 AWS ECS Fargate Module

![Terraform](https://img.shields.io/badge/Terraform-1.3+-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-ECS_Fargate-FF9900?logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📌 Overview

This module provisions a production-ready **AWS ECS Fargate infrastructure** with built-in support for load balancing, autoscaling, logging, and secure secret injection. It is designed for modern containerized applications running in a scalable and highly available environment.

---

## 🏗️ Architecture Features

* **Containerized Workloads** – Supports public & private images (DockerHub, ECR)
* **Secure Secret Injection** – Integrated with AWS Secrets Manager / SSM
* **Application Load Balancer (ALB)** – Optional path-based routing
* **HTTPS Support** – ACM integration for secure traffic
* **Autoscaling** – CPU, Memory & Request-based scaling policies
* **CloudWatch Logging** – Centralized logs with configurable retention
* **Container Insights** – Enhanced monitoring enabled
* **Safe Deployments** – Rolling updates with circuit breaker support

---

## 📁 Module Structure

```text id="p3x8sn"
modules/ecs/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

---

## 🏗️ Architecture

```text id="l9d2ks"
Internet
   ↓
ALB (Public Subnet)
   ↓
ECS Service (Private Subnet)
   ↓
RDS / External Services (Private Network)
```

---

## 🚀 Implementation Example

```hcl id="a9x3kd"
module "ecs" {
  source = "../modules/ecs"

  project_name = "myapp"
  environment  = "dev"
  region       = "us-east-1"

  subnets         = module.vpc.public_subnet_ids
  security_groups = [module.vpc.ecs_sg_id]
  
  enable_alb          = true
  vpc_id              = module.vpc.vpc_id
  alb_subnets         = module.vpc.public_subnet_ids
  alb_security_groups = [module.vpc.alb_sg_id]
  assign_public_ip    = true

  enable_https    = true
  certificate_arn = "arn:aws:acm:region:account:certificate/xxxx"

  secrets_arns = [module.db_secret.secret_arn]

  enable_logs        = true
  log_retention_days = 7
  health_check_grace_period = 60

  services = {
    frontend = {
      image             = "nginx:latest"
      port              = 80
      cpu               = "256"
      memory            = "512"
      desired_count     = 1
      path              = "/"
      priority          = 1
      health_check_path = "/"

      env     = {}
      secrets = []

      enable_autoscaling = false
      min_capacity       = 1
      max_capacity       = 2

      cpu_target     = 50
      memory_target  = 70
      request_target = 100
    }

    backend = {
      image             = "123456789.dkr.ecr.us-east-1.amazonaws.com/backend:latest"
      port              = 3000
      cpu               = "256"
      memory            = "512"
      desired_count     = 1
      path              = "/api*"
      priority          = 2
      health_check_path = "/health"

      env = {
        DB_HOST = module.rds.db_endpoint
        DB_PORT = module.rds.db_port
        DB_NAME = module.rds.db_name
        FRONTEND_URL = "*"
      }

      secrets = [
        {
          name      = "DB_USER"
          valueFrom = "${module.db_secret.secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${module.db_secret.secret_arn}:password::"
        }
      ]

      repository_credentials = null

      enable_autoscaling = true
      min_capacity       = 1
      max_capacity       = 3

      cpu_target     = 60
      memory_target  = 70
      request_target = 200
    }
  }
}
```

---

## 🔐 Image Support

### Public DockerHub

```hcl id="zv3x2p"
image = "nginx:latest"
```

### Private DockerHub

```hcl id="c7n8qa"
repository_credentials = "arn:aws:secretsmanager:..."
```

### AWS ECR (Recommended)

```hcl id="k8d3la"
image = "account-id.dkr.ecr.region.amazonaws.com/app:latest"
```

---

## 🔑 Secrets

Securely inject secrets via AWS Secrets Manager or SSM:

```hcl id="m2s8pw"
secrets = [
  {
    name      = "DB_PASSWORD"
    valueFrom = "arn:aws:secretsmanager:region:account:secret:db"
  }
]
```

---

## 📊 Logging

* Automatic CloudWatch Log Group creation
* Configurable retention period
* Container-level log streaming

```hcl id="w7q2zl"
enable_logs        = true
log_retention_days = 7
```

---

## 🌐 HTTPS (ACM)

Enable HTTPS via ALB:

```hcl id="u3n9vb"
enable_https    = true
certificate_arn = "your-acm-arn"
```

---

## 📈 Autoscaling

Supports:

* CPU Utilization
* Memory Utilization
* ALB Request Count per target

```hcl id="f2d8xm"
cpu_target     = 60
memory_target  = 70
request_target = 200
```

---

## 📤 Outputs

| Output     | Description       |
| ---------- | ----------------- |
| `alb_dns`  | ALB DNS name      |
| `services` | ECS service names |

---

## 🧠 Notes

* Path rewriting handled inside application (e.g., Nginx)
* Naming convention: `<project>-<environment>-<resource>`
* Fully modular and reusable design
* Production-safe rolling deployments enabled

---

## 👨‍💻 Author

**Muhammad Adeel**  :  
DevOps Engineer
