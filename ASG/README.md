
# 🚀 Terraform ASG Module

## 📌 Overview

Production-grade reusable Auto Scaling Group module designed for:

- Private subnet deployments
- Multi-environment infrastructure
- Immutable deployments
- Production workloads
- Enterprise reusable architectures

Supports:

- EC2 Auto Scaling
- ALB integration
- NLB integration
- Multiple Target Groups
- Launch Templates
- Rolling instance refresh
- CPU scaling
- Memory scaling
- Scheduled scaling
- Spot instances
- Mixed instance policies
- Additional EBS volumes
- Secure IMDSv2 metadata
- Optional SSM access

---

# ✅ Features

| Feature | Supported |
|---|---|
| Launch Template | ✅ |
| ALB Integration | ✅ |
| NLB Integration | ✅ |
| Multiple Target Groups | ✅ |
| CPU Scaling | ✅ |
| Memory Scaling | ✅ |
| Scheduled Scaling | ✅ |
| Spot Instances | ✅ |
| Mixed Instances Policy | ✅ |
| Rolling Refresh | ✅ |
| IMDSv2 | ✅ |
| Additional EBS Volumes | ✅ |
| SSM Access (via IAM policy) | ✅ |
| Scale-In Protection | ✅ |
| Capacity Rebalancing | ✅ |
| Private Subnet Deployments | ✅ |

---

# 📦 Resources Created

| Resource | Purpose |
|---|---|
| aws_launch_template | EC2 launch template |
| aws_autoscaling_group | Auto Scaling Group |
| aws_autoscaling_policy | CPU scaling |
| aws_autoscaling_policy | Memory scaling |
| aws_autoscaling_schedule | Scheduled scaling |

---

# 🚀 Example Usage

## Basic ASG

```hcl
module "asg" {

  source = "./modules/asg"

  project_name = "app"
  environment  = "prod"

  ami_id        = "ami-xxxxxxxx"
  instance_type = "t3.micro"

  subnet_ids = module.vpc.private_subnets

  security_group_ids = [
    module.vpc.app_sg_id
  ]

  scaling = {
    min     = 1
    max     = 2
    desired = 1
  }
  tags = {
    Project     = "monitoring"
    Environment = "prod"
  }
}
```
---

## Full Enterprise Example

```hcl
module "asg" {

  source = "./modules/asg"

  project_name = "monitoring"
  environment  = "prod"

  ami_id = "ami-xxxxxxxx"

  # ---------------------------------------------------------
  # INSTANCE
  # ---------------------------------------------------------
  enable_mixed_instances_policy = true

  instance_types = [
    "t3.medium",
    "t3.large",
    "t3a.medium"
  ]

  key_name = var.key_name

  user_data = file("${path.module}/userdata.sh")

  # ---------------------------------------------------------
  # NETWORK
  # ---------------------------------------------------------
  subnet_ids = module.vpc.private_subnets

  security_group_ids = [
    module.vpc.monitoring_sg_id
  ]

  # ---------------------------------------------------------
  # SCALING
  # ---------------------------------------------------------
  scaling = {
    min     = 2
    max     = 10
    desired = 2
  }

  enable_cpu_scaling    = true
  cpu_target_value      = 60

  enable_memory_scaling = true
  memory_target_value   = 70

  # ---------------------------------------------------------
  # SCHEDULED SCALING
  # ---------------------------------------------------------
  enable_scheduled_scaling = true

  scheduled_scaling = {

    scale_up_cron = "0 8 * * MON-FRI"

    scale_down_cron = "0 20 * * MON-FRI"

    scale_up_min     = 2
    scale_up_max     = 10
    scale_up_desired = 4

    scale_down_min     = 1
    scale_down_max     = 2
    scale_down_desired = 1
  }

  # ---------------------------------------------------------
  # LOAD BALANCER
  # ---------------------------------------------------------
  target_group_arns = [
    module.alb.target_group_arns["api"],
    module.alb.target_group_arns["admin"]
  ]

  # ---------------------------------------------------------
  # STORAGE
  # ---------------------------------------------------------
  root_volume = {
    device_name = "/dev/xvda"
    size        = 50
    type        = "gp3"
    encrypted   = true
  }

  additional_ebs_volumes = [
    {
      device_name = "/dev/xvdb"
      size        = 100
      type        = "gp3"
      encrypted   = true
    }
  ]

  # ---------------------------------------------------------
  # INSTANCE REFRESH
  # ---------------------------------------------------------
  enable_instance_refresh = true

  instance_refresh_min_healthy_percentage = 50

  # ---------------------------------------------------------
  # SSM
  # ---------------------------------------------------------
  enable_ssm = true

  # ---------------------------------------------------------
  # PROTECTION
  # ---------------------------------------------------------
  protect_from_scale_in = true

  capacity_rebalance = true

  # ---------------------------------------------------------
  # TAGS
  # ---------------------------------------------------------
  tags = {
    Project     = "monitoring"
    Environment = "prod"
  }
}
```
---

## NOTE
CloudWatch Agent must be installed via user_data or bootstrap script. IAM permissions are handled automatically by module when enable_memory_scaling = true.

---

## 🔒 Security Features
- IMDSv2 enforced
- Encrypted EBS volumes
- Security group isolation
- SSM Session Manager support
- Private subnet ready

---

## ✅ Recommended For
- ECS Capacity Providers
- APIs
- Monitoring Platforms
- Backend Services
- Enterprise Infrastructure
- Internal Platforms
- HA Workloads

---

## 🏷 Naming Convention
- project-prod-ec2-role
- project-prod-ec2-profile