# 🚀 AWS ECS Fargate Module (Production Grade)

![Terraform](https://img.shields.io/badge/Terraform-1.3+-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-ECS_Fargate-FF9900?logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📌 Overview

This Terraform module provisions a **production-ready AWS ECS Fargate platform** with:

- Multi-service ECS architecture
- Application Load Balancer (ALB)
- Path-based and host-based routing
- Flexible listener modes (HTTP / HTTPS / Redirect / Mixed)
- Autoscaling (CPU / Memory / Request-based)
- CloudWatch logging
- Secrets Manager integration
- Optional WAF integration
- Optional Blue/Green deployments (CodeDeploy)
- Secure production networking patterns

Designed to be **reusable across all environments and project types** — from monoliths to microservices.

---

## 🧠 Design Philosophy

Built to support:

- Monolithic applications
- Microservices architectures
- Multi-domain SaaS platforms
- API + Frontend split deployments
- Internal and public-facing services

> ✔ Single unified listener control — no multiple boolean flags:
> ```hcl
> listener_mode = "http_only" | "http_to_https" | "https_only" | "dual"
> ```

---

## 🏗️ Architecture Features

### Core
- ECS Fargate (serverless containers)
- Multi-service deployment in a single module call
- Separate IAM roles for task execution and task runtime
- `default_service` control for root traffic routing

### Networking
- Application Load Balancer (ALB)
- Path-based routing (`/api*`, `/admin*`)
- Host-based routing (`api.domain.com`, `app.domain.com`)
- Public/private subnet support
- Configurable `assign_public_ip` per environment

### Traffic Control

| Mode | Behavior |
|------|----------|
| `http_only` | Only HTTP listener active |
| `https_only` | Only HTTPS listener active |
| `http_to_https` | HTTP redirects to HTTPS |
| `dual` | HTTP + HTTPS both active (no redirect) |

### Security
- AWS Secrets Manager integration for sensitive env vars
- Private subnet deployment for ECS tasks
- ALB in public subnets only
- Optional ECS Exec for live container debugging
- Optional WAF integration (`enable_waf`, `waf_web_acl_id`)

### Observability
- CloudWatch log group per service
- Container Insights enabled on cluster
- Configurable log retention

### Scaling
- CPU utilization-based autoscaling
- Memory utilization-based autoscaling
- Request-count-based autoscaling (`request_target`)

### Deployment
- Rolling deployment (default) with circuit breaker enabled
- Optional Blue/Green via AWS CodeDeploy (`enable_blue_green`)

---

## 📁 Module Structure

```text
modules/ecs/
├── main.tf          # Core resources (cluster, services, ALB, listeners)
├── variables.tf     # All input variable definitions
├── outputs.tf       # Exported values
└── README.md        # This file
```

---

## 🚀 Usage Example

```hcl
module "ecs" {
  source = "../../modules/ecs"

  project_name = var.project_name
  environment  = var.environment
  region       = var.aws_region

  # ---------------- Networking ----------------
  vpc_id              = module.vpc.vpc_id
  subnets             = module.vpc.private_subnet_ids
  security_groups     = [module.vpc.app_sg_id]

  alb_subnets         = module.vpc.public_subnet_ids
  alb_security_groups = [module.vpc.elb_sg_id]

  assign_public_ip = false

  # ---------------- Listener Mode ----------------
  listener_mode   = "http_to_https"   # http_only | https_only | http_to_https | dual
  certificate_arn = module.acm.certificate_arn  # required when HTTPS is used

  # ---------------- WAF (Optional) ----------------
  enable_waf     = true
  waf_web_acl_id = aws_wafv2_web_acl.main.arn     # Null when waf=false

  # ---------------- Secrets IAM Access ----------------
  secrets_arns = [module.mongo_secret.secret_arn]

  # ---------------- Logging ----------------
  enable_logs        = true
  log_retention_days = 7

  # ---------------- Deployment ----------------
  health_check_grace_period = 60
  enable_exec               = true
  enable_blue_green         = false
  deployment_min_healthy    = 50
  deployment_max_percent    = 200

  default_service = "backend"   # handles root / traffic

  # ---------------- Services ----------------
  services = {
    frontend = {
      image         = "nginx:latest"
      port          = 80
      cpu           = "256"
      memory        = "512"
      desired_count = 1

      path     = "/"
      host     = "app.example.com"   # host-based routing (optional)
      priority = 1

      health_check_path     = "/"
      health_check_protocol = "HTTP"
      health_check_matcher  = "200-399"

      env     = {}
      secrets = []

      enable_autoscaling = false
      min_capacity       = 1
      max_capacity       = 2
      cpu_target         = 50
      memory_target      = 70
      request_target     = 200
    }

    backend = {
      image         = "${module.ecr_backend.repository_url}:latest"
      port          = 5000
      cpu           = "256"
      memory        = "512"
      desired_count = 1

      path     = "/api*"
      host     = "api.example.com"   # host-based routing (optional)
      priority = 2

      health_check_path     = "/health"
      health_check_protocol = "HTTP"
      health_check_matcher  = "200-399"

      env = {
        FRONTEND_URL = "*"
      }

      secrets = [
        {
          name      = "MONGO_URI"
          valueFrom = "${module.mongo_secret.secret_arn}:MONGO_URI::"
        }
      ]

      repository_credentials = null

      enable_autoscaling = true
      min_capacity       = 1
      max_capacity       = 3
      cpu_target         = 60
      memory_target      = 70
      request_target     = 200
    }
  }

  depends_on = [module.mongo_secret]
}
```

---

## 🔐 Image Support

### Public Images
```hcl
image = "nginx:latest"
```

### Private DockerHub
```hcl
repository_credentials = "arn:aws:secretsmanager:region:account:secret:dockerhub-creds"
```

### AWS ECR
```hcl
image = "123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest"
```

---

## 🔑 Secrets Management

Two layers work together to securely inject secrets:

### Layer 1 — Task-level injection (env var inside container)
```hcl
secrets = [
  {
    name      = "MONGO_URI"
    valueFrom = "arn:aws:secretsmanager:region:account:secret:db-secret:MONGO_URI::"
  },
  {
    name      = "API_KEY"
    valueFrom = "arn:aws:secretsmanager:region:account:secret:api-secret:key::"
  }
]
```

### Layer 2 — IAM permission (allows ECS to read the secret)
```hcl
secrets_arns = [module.mongo_secret.secret_arn]
```

> Both layers are required. `secrets` injects the value; `secrets_arns` grants the IAM permission to fetch it.

---

## 📊 Logging

Each service gets its own CloudWatch log group:

```hcl
enable_logs        = true
log_retention_days = 7
```

Log groups are named: `/ecs/{project_name}-{environment}-{service_name}`

---

## 🌐 HTTPS / TLS

TLS is terminated at the ALB. Set `listener_mode` and provide the ACM certificate:

```hcl
# Recommended for production
listener_mode   = "http_to_https"
certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/xxxx"

# Strictest — HTTPS only
listener_mode = "https_only"

# Both active without redirect — useful behind CloudFront
listener_mode = "dual"
```

---

## 🔁 Autoscaling

Configured per service. Supports CPU, memory, and request-count targets:

```hcl
enable_autoscaling = true
min_capacity       = 1
max_capacity       = 4
cpu_target         = 60    # scale out when CPU > 60%
memory_target      = 70    # scale out when memory > 70%
request_target     = 200   # scale out when requests/target > 200
```

---

## 🚀 Deployment Modes

### Rolling (default)
ECS native rolling update with circuit breaker enabled. No additional setup required.

### Blue/Green (optional)
Enables AWS CodeDeploy integration for traffic-shifting deployments:

```hcl
enable_blue_green = true
```

---

## 🛡️ WAF Integration (Optional)

Attach an AWS WAF Web ACL to the ALB:

```hcl
enable_waf     = true
waf_web_acl_id = "arn:aws:wafv2:us-east-1:123456789:regional/webacl/my-acl/xxxx"
```

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `cluster_name` | ECS cluster name |
| `cluster_arn` | ECS cluster ARN |
| `alb_dns_name` | ALB DNS name |
| `service_names` | Map of deployed ECS service names |
| `task_definition_arns` | Map of task definition ARNs |

---

## 🧠 Production Notes

- `default_service` routes all unmatched traffic (root `/`) to the specified service
- Rolling deployments have circuit breaker enabled — failed deployments auto-rollback
- `assign_public_ip = false` keeps ECS tasks fully private (requires NAT Gateway)
- `enable_exec = true` allows live `aws ecs execute-command` for debugging
- Fully reusable across `dev`, `staging`, and `prod` with different `tfvars`
- Compatible with CloudFront as CDN layer in front of ALB

---

## 🚀 Planned Extensions

- [ ] Canary deployments
- [ ] WAF rule automation
- [ ] Multi-region active-active ECS
- [ ] Service mesh (AWS App Mesh support)

---

## 👨‍💻 Author

**Muhammad Adeel** — DevOps Engineer

[![GitHub](https://img.shields.io/badge/GitHub-Portfolio-181717?logo=github)](https://github.com/)
