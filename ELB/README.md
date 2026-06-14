# 🚀 Terraform Enterprise ELB Module

## 📌 Overview

Production-grade reusable AWS Load Balancer module supporting:

- Application Load Balancer (ALB)
- Network Load Balancer (NLB)
- Multiple Target Groups
- HTTP / HTTPS / TCP / TLS / UDP / TCP_UDP listeners
- Path-based routing
- Host-based routing
- HTTP → HTTPS redirect
- ACM SSL certificates
- Optional EC2 target attachments
- ASG integration
- ECS-ready architecture
- Internal/Public Load Balancers
- Access logs
- Health check customization
- Stickiness
- WAF integration
- Advanced ALB settings
- CloudFront-ready outputs

---

## 📁 Structure

```text
ELB/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

---

# ✅ Features

| Feature | Supported |
|---|---|
| ALB | ✅ |
| NLB | ✅ |
| Multi Target Groups | ✅ |
| Path Routing | ✅ |
| Host Routing | ✅ |
| HTTP Listener | ✅ |
| HTTPS Listener | ✅ |
| TCP Listener | ✅ |
| TLS Listener | ✅ |
| UDP Listener | ✅ |
| TCP_UDP Listener | ✅ |
| HTTPS Redirect | ✅ |
| ACM SSL | ✅ |
| Optional Target Attachments | ✅ |
| ASG Compatible | ✅ |
| ECS Compatible | ✅ |
| Access Logs | ✅ |
| Stickiness | ✅ |
| WAF Integration | ✅ |
| Internal/Public LB | ✅ |
| Health Checks | ✅ |
| Proxy Protocol v2 | ✅ |
| Slow Start | ✅ |
| Advanced ALB Settings | ✅ |
| CloudFront-ready | ✅ |

---

# 📦 Resources Created

| Resource | Purpose |
|---|---|
| aws_lb | Load Balancer |
| aws_lb_target_group | Target Groups |
| aws_lb_listener | ALB/NLB listeners |
| aws_lb_listener_rule | Path/Host routing |
| aws_lb_target_group_attachment | Optional EC2 attachments |
| aws_wafv2_web_acl_association | Optional WAF association |

---

# 🚀 Scenario 1 — EC2 + ALB

```hcl
module "elb" {

  source = "./modules/elb"

  project_name = "app"
  environment  = "prod"

  name = "api"

  # ---------------------------------------------------------
  # LOAD BALANCER
  # ---------------------------------------------------------
  lb_type = "application"

  internal = false

  vpc_id = module.vpc.vpc_id

  subnet_ids = module.vpc.public_subnets

  security_group_ids = [
    module.vpc.elb_sg_id
  ]

  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true

  idle_timeout               = 60
  drop_invalid_header_fields = true

  # ---------------------------------------------------------
  # ACCESS LOGS
  # ---------------------------------------------------------
  enable_access_logs = true

  access_logs_bucket = module.s3.bucket_id

  access_logs_prefix = "alb-logs"

  # ---------------------------------------------------------
  # WAF
  # ---------------------------------------------------------
  enable_waf = true

  waf_acl_arn = module.waf.waf_acl_arn

  # ---------------------------------------------------------
  # LISTENERS
  # ---------------------------------------------------------
  enable_http_listener  = true
  enable_https_listener = true

  enable_https_redirect = true

  http_listener_port  = 80
  https_listener_port = 443

  certificate_arn = module.acm.certificate_arn

  ssl_policy = "ELBSecurityPolicy-2016-08"

  # ---------------------------------------------------------
  # TARGET GROUPS
  # ---------------------------------------------------------
  default_target_group = "api"

  target_groups = {

    api = {

      port     = 8080
      protocol = "HTTP"

      target_type = "instance"

      target_ids = [
        module.ec2.instance_id
      ]

      deregistration_delay = 300

      # ---------------------------------------------------------
      # HEALTH CHECKS
      # ---------------------------------------------------------
      health_check_enabled  = true
      health_check_protocol = "HTTP"
      health_check_path     = "/health"

      health_check_port = "traffic-port"

      health_check_interval = 30
      health_check_timeout  = 5

      healthy_threshold   = 2
      unhealthy_threshold = 2

      matcher = "200-399"

      # ---------------------------------------------------------
      # STICKINESS
      # ---------------------------------------------------------
      enable_stickiness = true

      stickiness_type = "lb_cookie"

      # ---------------------------------------------------------
      # ALB ADVANCED
      # ---------------------------------------------------------
      slow_start = 0

      load_balancing_algorithm_type = "round_robin"

      # ---------------------------------------------------------
      # ROUTING
      # ---------------------------------------------------------
      paths = [
        "/api/*"
      ]

      host_headers = [
        "api.example.com"
      ]

      priority = 100
    }
  }

  # ---------------------------------------------------------
  # TAGS
  # ---------------------------------------------------------
  tags = {
    Project     = "app"
    Environment = "prod"
  }
}
```

---

# 🚀 Scenario 2 — ASG + ALB

```hcl
module "elb" {

  source = "./modules/elb"

  project_name = "monitoring"
  environment  = "prod"

  name = "monitoring"

  lb_type = "application"

  internal = false

  vpc_id = module.vpc.vpc_id

  subnet_ids = module.vpc.public_subnets

  security_group_ids = [
    module.vpc.elb_sg_id
  ]

  enable_http_listener  = true
  enable_https_listener = true

  enable_https_redirect = true

  certificate_arn = module.acm.certificate_arn

  default_target_group = "api"

  target_groups = {

    api = {

      port     = 8080
      protocol = "HTTP"

      target_type = "instance"

      health_check_protocol = "HTTP"
      health_check_path     = "/"

      paths = [
        "/api/*"
      ]

      host_headers = [
        "api.example.com"
      ]
    }

    admin = {

      port     = 9090
      protocol = "HTTP"

      target_type = "instance"

      health_check_protocol = "HTTP"
      health_check_path     = "/"

      paths = [
        "/admin/*"
      ]

      host_headers = [
        "admin.example.com"
      ]
    }
  }

  tags = {
    Project     = "monitoring"
    Environment = "prod"
  }
}
```

---

# 🚀 Scenario 3 — ASG + NLB

```hcl
module "elb" {

  source = "./modules/elb"

  project_name = "signoz"
  environment  = "prod"

  name = "signoz"

  # ---------------------------------------------------------
  # LOAD BALANCER
  # ---------------------------------------------------------
  lb_type = "network"

  internal = false

  vpc_id = module.vpc.vpc_id

  subnet_ids = module.vpc.public_subnets

  # OPTIONAL
  security_group_ids = [
    module.vpc.elb_sg_id
  ]

  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true

  # ---------------------------------------------------------
  # ACCESS LOGS
  # ---------------------------------------------------------
  enable_access_logs = true

  access_logs_bucket = module.s3.bucket_id

  access_logs_prefix = "nlb-logs"

  # ---------------------------------------------------------
  # TLS — single or multiple ports
  # ---------------------------------------------------------
  tls_listeners = {
  ui = {
    port         = 443
    target_group = "signoz"
    ssl_policy   = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    certificate_arn = module.acm.certificate_arn
   }
  }

  # ---------------------------------------------------------
  # TCP — single or multiple ports
  # ---------------------------------------------------------
  tcp_listeners = {
  otel-grpc = {
    port         = 4317
    target_group = "otel-grpc"
   }
  otel-http = {
    port         = 4318
    target_group = "otel-http"
   }
  }

  # ---------------------------------------------------------
  # UDP — optional
  # ---------------------------------------------------------
  udp_listeners = {}

  # ---------------------------------------------------------
  # TCP_UDP — optional
  # ---------------------------------------------------------
  tcp_udp_listeners = {}
  # ---------------------------------------------------------
  # TARGET GROUPS
  # ---------------------------------------------------------
  default_target_group = "signoz"

  target_groups = {

    signoz = {

      port     = 3301
      protocol = "TCP"

      target_type = "instance"

      deregistration_delay = 300

      # ---------------------------------------------------------
      # HEALTH CHECKS
      # ---------------------------------------------------------
      health_check_protocol = "TCP"

      health_check_port = "traffic-port"

      health_check_interval = 30
      health_check_timeout  = 10

      healthy_threshold   = 2
      unhealthy_threshold = 2

      # ---------------------------------------------------------
      # NLB ADVANCED
      # ---------------------------------------------------------
      proxy_protocol_v2 = false
    }
  }

  tags = {
    Project     = "signoz"
    Environment = "prod"
  }
}
```

---

# 🚀 Host Based Routing Example

```hcl
target_groups = {

  api = {

    port     = 8080
    protocol = "HTTP"

    host_headers = [
      "api.example.com"
    ]
  }

  admin = {

    port     = 9090
    protocol = "HTTP"

    host_headers = [
      "admin.example.com"
    ]
  }
}
```

---

# 🚀 Path Based Routing Example

```hcl
target_groups = {

  api = {

    port     = 8080
    protocol = "HTTP"

    paths = [
      "/api/*"
    ]
  }

  admin = {

    port     = 9090
    protocol = "HTTP"

    paths = [
      "/admin/*"
    ]
  }
}
```

---

# 📤 Outputs

| Output | Description |
|---|---|
| lb_arn | Load Balancer ARN |
| lb_dns_name | Load Balancer DNS |
| lb_zone_id | Route53 Alias Zone ID |
| lb_name | Load Balancer Name |
| target_group_arns | Map of Target Group ARNs |

---

# 🧠 Architecture Notes

## EC2 Architecture

```text
EC2 → Target Group → ELB
```

Use:
- target_ids
- static infrastructure

---

## ASG Architecture

```text
ASG → Target Group → ELB
```

Do NOT use:
- target_ids

ASG automatically registers instances.

---

## ECS Architecture

```text
ECS Service → Target Group → ELB
```

Use:
- target_group_arns output
- ECS service attachment

---

# 🔥 CloudFront Integration

This module is CloudFront-ready.

Example:

```hcl
origin_domain_name = module.elb.lb_dns_name
```

Recommended architecture:

```text
User
 ↓
CloudFront
 ↓
ALB
 ↓
Application
```

---

# 🔒 Security Features

- HTTPS/TLS support
- ACM SSL integration
- WAF integration
- Security Group support
- Private/Internal load balancers
- Invalid header protection
- Target health monitoring

---

# 🏷 Example Resource Naming

```text
abc-prod-api-lb
abc-prod-api-tg
```

---

# ✅ Recommended For

- APIs
- ECS Services
- ASG Architectures
- Monitoring Platforms
- Internal Services
- Enterprise Infrastructure
- HA Applications
- CloudFront Origins
- TCP/UDP Applications