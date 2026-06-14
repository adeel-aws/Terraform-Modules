# Auto-fetch AMI root device name
data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------
# BASE EC2 IAM ROLE (NEW)
# ---------------------------------------------------------
resource "aws_iam_role" "ec2" {

  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-ec2-role"
  })
}

resource "aws_iam_instance_profile" "ec2" {

  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-ec2-profile"
  })
}

# ---------------------------------------------------------
# OPTIONAL SSM IAM POLICY ATTACHMENT
# ---------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ssm" {

  count = var.enable_ssm ? 1 : 0

  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ---------------------------------------------------------
# OPTIONAL CLOUDWATCH AGENT (MEMORY SCALING)
# ---------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cwagent" {

  count = var.enable_memory_scaling ? 1 : 0

  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ---------------------------------------------------------
# LAUNCH TEMPLATE
# ---------------------------------------------------------
resource "aws_launch_template" "this" {

  name_prefix = "${local.name_prefix}-lt-"

  image_id = var.ami_id

  instance_type = var.enable_mixed_instances_policy ? null : var.instance_type

  key_name = var.key_name

  vpc_security_group_ids = var.security_group_ids

  update_default_version = true

  user_data = var.user_data != null ? base64encode(var.user_data) : null

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # ---------------------------------------------------------
  # ROOT VOLUME
  # ---------------------------------------------------------
block_device_mappings {
  device_name = data.aws_ami.this.root_device_name   # ← auto-detected

  ebs {
    volume_size           = var.root_volume.size
    volume_type           = var.root_volume.type
    encrypted             = var.root_volume.encrypted
    delete_on_termination = true
  }
}

  # ---------------------------------------------------------
  # ADDITIONAL EBS VOLUMES
  # ---------------------------------------------------------
  dynamic "block_device_mappings" {
    for_each = var.additional_ebs_volumes

    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_size           = block_device_mappings.value.size
        volume_type           = block_device_mappings.value.type
        encrypted             = block_device_mappings.value.encrypted
        delete_on_termination = true
      }
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = "${local.name_prefix}-instance"
    })
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-lt"
  })
}

# ---------------------------------------------------------
# AUTO SCALING GROUP
# ---------------------------------------------------------
resource "aws_autoscaling_group" "this" {

  name = "${local.name_prefix}-asg"

  vpc_zone_identifier = var.subnet_ids

  min_size         = var.scaling.min
  max_size         = var.scaling.max
  desired_capacity = var.scaling.desired

  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  force_delete = var.force_delete

  termination_policies = var.termination_policies

  target_group_arns = var.target_group_arns

  capacity_rebalance    = var.capacity_rebalance
  protect_from_scale_in = var.protect_from_scale_in

  dynamic "launch_template" {
    for_each = var.enable_mixed_instances_policy ? [] : [1]

    content {
      id      = aws_launch_template.this.id
      version = aws_launch_template.this.latest_version
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.enable_mixed_instances_policy ? [1] : []

    content {

      instances_distribution {
        on_demand_base_capacity                  = var.on_demand_base_capacity
        on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
        spot_allocation_strategy                 = var.spot_allocation_strategy
      }

      launch_template {

        launch_template_specification {
          launch_template_id = aws_launch_template.this.id
          version            = aws_launch_template.this.latest_version
        }

        dynamic "override" {
          for_each = var.instance_types

          content {
            instance_type = override.value
          }
        }
      }
    }
  }

  dynamic "instance_refresh" {
    for_each = var.enable_instance_refresh ? [1] : []

    content {
      strategy = "Rolling"

      preferences {
        min_healthy_percentage = var.instance_refresh_min_healthy_percentage
      }

      triggers = ["launch_template"]
    }
  }

 dynamic "tag" {
  for_each = merge(var.tags, {
    Instance = "${local.name_prefix}-instance"
  })

  content {
    key                 = tag.key
    value               = tag.value
    propagate_at_launch = true
  }
}

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------
# CPU TARGET TRACKING
# ---------------------------------------------------------
resource "aws_autoscaling_policy" "cpu_target_tracking" {

  count = var.enable_cpu_scaling ? 1 : 0

  name = "${local.name_prefix}-cpu-scaling-policy"

  autoscaling_group_name = aws_autoscaling_group.this.name

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {

    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target_value
  }
}

# ---------------------------------------------------------
# MEMORY TARGET TRACKING
# ---------------------------------------------------------
resource "aws_autoscaling_policy" "memory_target_tracking" {

  count = var.enable_memory_scaling ? 1 : 0

  name = "${local.name_prefix}-memory-scaling-policy"

  autoscaling_group_name = aws_autoscaling_group.this.name

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {

    customized_metric_specification {
      metric_name = var.memory_metric_name
      namespace   = var.memory_metric_namespace
      statistic   = "Average"
    }

    target_value = var.memory_target_value
  }
}

# ---------------------------------------------------------
# SCHEDULED SCALING
# ---------------------------------------------------------
resource "aws_autoscaling_schedule" "scale_up" {

  count = var.enable_scheduled_scaling ? 1 : 0

  scheduled_action_name = "${local.name_prefix}-scale-up"

  autoscaling_group_name = aws_autoscaling_group.this.name

  recurrence = var.scheduled_scaling.scale_up_cron

  min_size         = var.scheduled_scaling.scale_up_min
  max_size         = var.scheduled_scaling.scale_up_max
  desired_capacity = var.scheduled_scaling.scale_up_desired
}

resource "aws_autoscaling_schedule" "scale_down" {

  count = var.enable_scheduled_scaling ? 1 : 0

  scheduled_action_name = "${local.name_prefix}-scale-down"

  autoscaling_group_name = aws_autoscaling_group.this.name

  recurrence = var.scheduled_scaling.scale_down_cron

  min_size         = var.scheduled_scaling.scale_down_min
  max_size         = var.scheduled_scaling.scale_down_max
  desired_capacity = var.scheduled_scaling.scale_down_desired
}