locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ================================================================
#  ECS CLUSTER
# ================================================================

resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ================================================================
#  IAM — EXECUTION ROLE
#  Used by ECS agent to pull images, fetch secrets, write logs
# ================================================================

resource "aws_iam_role" "execution" {
  name = "${local.name_prefix}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_base" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Secrets Manager read — grants execution role access to pull secrets at task start
resource "aws_iam_policy" "secrets_read" {
  count = length(var.secrets_arns) > 0 ? 1 : 0
  name  = "${local.name_prefix}-secrets-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = var.secrets_arns
    }]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_read" {
  count      = length(var.secrets_arns) > 0 ? 1 : 0
  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.secrets_read[0].arn
}

# ================================================================
#  IAM — TASK ROLE
#  Used by the running container itself (app-level AWS calls)
# ================================================================

resource "aws_iam_role" "task" {
  name = "${local.name_prefix}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# SSM Parameter Store read
resource "aws_iam_policy" "ssm_read" {
  name = "${local.name_prefix}-ssm-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParameterHistory"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_read" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.ssm_read.arn
}

# CloudWatch metrics publishing
resource "aws_iam_policy" "cloudwatch_metrics" {
  name = "${local.name_prefix}-cw-metrics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["cloudwatch:PutMetricData"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_metrics" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.cloudwatch_metrics.arn
}

# S3 read (safe baseline — many apps need config/asset reads)
resource "aws_iam_policy" "s3_read" {
  name = "${local.name_prefix}-s3-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:ListBucket"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.s3_read.arn
}

# ECS Exec — allows `aws ecs execute-command` for live debugging
resource "aws_iam_policy" "ecs_exec" {
  count = var.enable_exec ? 1 : 0
  name  = "${local.name_prefix}-ecs-exec"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec" {
  count      = var.enable_exec ? 1 : 0
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.ecs_exec[0].arn
}

# ================================================================
#  CLOUDWATCH LOG GROUPS (one per service)
# ================================================================

resource "aws_cloudwatch_log_group" "this" {
  for_each = var.enable_logs ? var.services : {}

  name              = "/ecs/${local.name_prefix}-${each.key}"
  retention_in_days = var.log_retention_days
}

# ================================================================
#  ALB
# ================================================================

resource "aws_lb" "this" {
  count = var.enable_alb ? 1 : 0

  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  subnets            = var.alb_subnets
  security_groups    = var.alb_security_groups

  tags = {
    Name        = "${local.name_prefix}-alb"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ================================================================
#  WAF ASSOCIATION
# ================================================================

resource "aws_wafv2_web_acl_association" "alb" {
  count = var.enable_alb && var.enable_waf && var.waf_web_acl_id != null ? 1 : 0

  resource_arn = aws_lb.this[0].arn
  web_acl_arn  = var.waf_web_acl_id
}

# ================================================================
#  TARGET GROUPS
# ================================================================

resource "aws_lb_target_group" "this" {
  for_each = var.enable_alb ? var.services : {}

  name        = "${local.name_prefix}-${each.key}"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = each.value.health_check_path
    protocol            = each.value.health_check_protocol
    matcher             = each.value.health_check_matcher
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${local.name_prefix}-${each.key}-tg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ================================================================
#  ALB LISTENERS
#
#  Mode          | :80 listener     | :443 listener
#  --------------|------------------|------------------
#  http_only     | forward          | none
#  https_only    | none             | forward
#  http_to_https | redirect → 443   | forward
#  dual          | forward          | forward  (no redirect)
# ================================================================

# ---- http_only — HTTP :80 forward ----
resource "aws_lb_listener" "http_only" {
  count = var.enable_alb && var.listener_mode == "http_only" ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[var.default_service].arn
  }
}

# ---- http_to_https — HTTP :80 redirect ----
resource "aws_lb_listener" "http_redirect" {
  count = var.enable_alb && var.listener_mode == "http_to_https" ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ---- http_to_https / https_only — HTTPS :443 forward ----
resource "aws_lb_listener" "https" {
  count = (
    var.enable_alb &&
    contains(["http_to_https", "https_only"], var.listener_mode)
  ) ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[var.default_service].arn
  }
}

# ---- dual — HTTP :80 forward (no redirect) ----
resource "aws_lb_listener" "dual_http" {
  count = var.enable_alb && var.listener_mode == "dual" ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[var.default_service].arn
  }
}

# ---- dual — HTTPS :443 forward ----
resource "aws_lb_listener" "dual_https" {
  count = (
    var.enable_alb &&
    var.listener_mode == "dual"
  ) ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[var.default_service].arn
  }
}

# ================================================================
#  LISTENER RULES (path + optional host routing per service)
#
#  Rules always attach to the primary "inbound" HTTPS listener
#  when HTTPS is active, otherwise to the HTTP listener.
#  For dual mode, rules attach to the HTTPS listener so that
#  path-routing works on both ports via the shared target groups.
# ================================================================

locals {
  # Resolve which listener ARN to attach rules to based on mode
  active_listener_arn = (
    var.listener_mode == "http_to_https" ? aws_lb_listener.https[0].arn :
    var.listener_mode == "https_only"    ? aws_lb_listener.https[0].arn :
    var.listener_mode == "dual"          ? aws_lb_listener.dual_https[0].arn :
    aws_lb_listener.http_only[0].arn     # http_only
  )
}

resource "aws_lb_listener_rule" "this" {
  for_each = var.enable_alb ? var.services : {}

  listener_arn = local.active_listener_arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  # Path-based routing
  condition {
    path_pattern {
      values = [each.value.path]
    }
  }

  # Optional host-based routing (only added when host is set)
  dynamic "condition" {
    for_each = lookup(each.value, "host", null) != null ? [1] : []

    content {
      host_header {
        values = [each.value.host]
      }
    }
  }
}

# For dual mode, also attach the same rules to the HTTP :80 listener
# so path-routing works on both ports (CloudFront hits :80)
resource "aws_lb_listener_rule" "dual_http" {
  for_each = var.enable_alb && var.listener_mode == "dual" ? var.services : {}

  listener_arn = aws_lb_listener.dual_http[0].arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path]
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "host", null) != null ? [1] : []

    content {
      host_header {
        values = [each.value.host]
      }
    }
  }
}

# ================================================================
#  TASK DEFINITIONS
# ================================================================

resource "aws_ecs_task_definition" "this" {
  for_each = var.services

  family                   = "${local.name_prefix}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name  = each.key
    image = each.value.image

    portMappings = [{
      containerPort = each.value.port
      hostPort      = each.value.port
      protocol      = "tcp"
    }]

    environment = [
      for k, v in each.value.env : { name = k, value = v }
    ]

    secrets = [
      for s in each.value.secrets : {
        name      = s.name
        valueFrom = s.valueFrom
      }
    ]

    logConfiguration = var.enable_logs ? {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${local.name_prefix}-${each.key}"
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    } : null

    essential = true
  }])

  tags = {
    Name        = "${local.name_prefix}-${each.key}"
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

# ================================================================
#  ECS SERVICES
# ================================================================

resource "aws_ecs_service" "this" {
  for_each = var.services

  name            = "${local.name_prefix}-${each.key}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds  = var.health_check_grace_period
  deployment_minimum_healthy_percent = var.deployment_min_healthy
  deployment_maximum_percent         = var.deployment_max_percent

  enable_execute_command = var.enable_exec

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  dynamic "deployment_controller" {
    for_each = var.enable_blue_green ? [1] : []
    content {
      type = "CODE_DEPLOY"
    }
  }

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_groups
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.enable_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.this[each.key].arn
      container_name   = each.key
      container_port   = each.value.port
    }
  }

  tags = {
    Name        = "${local.name_prefix}-${each.key}"
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [
    aws_lb_listener.http_only,
    aws_lb_listener.http_redirect,
    aws_lb_listener.https,
    aws_lb_listener.dual_http,
    aws_lb_listener.dual_https,
    aws_iam_role_policy_attachment.execution_base,
    aws_iam_role_policy_attachment.secrets_read,
  ]
}

# ================================================================
#  AUTOSCALING
# ================================================================

resource "aws_appautoscaling_target" "this" {
  for_each = { for k, v in var.services : k => v if v.enable_autoscaling }

  max_capacity       = each.value.max_capacity
  min_capacity       = each.value.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.this]
}

resource "aws_appautoscaling_policy" "cpu" {
  for_each = { for k, v in var.services : k => v if v.enable_autoscaling }

  name               = "${local.name_prefix}-${each.key}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = each.value.cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "memory" {
  for_each = { for k, v in var.services : k => v if v.enable_autoscaling }

  name               = "${local.name_prefix}-${each.key}-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = each.value.memory_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "requests" {
  for_each = {
    for k, v in var.services : k => v
    if v.enable_autoscaling && v.request_target != null
  }

  name               = "${local.name_prefix}-${each.key}-requests"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = "${aws_lb.this[0].arn_suffix}/${aws_lb_target_group.this[each.key].arn_suffix}"
    }
    target_value       = each.value.request_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
