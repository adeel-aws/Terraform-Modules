locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------- ECS Cluster ----------------
resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ---------------- IAM - Execution Role ----------------
resource "aws_iam_role" "execution" {
  name = "${local.name_prefix}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------- IAM - Task Role ----------------
resource "aws_iam_role" "task" {
  name = "${local.name_prefix}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# ---------------- IAM - Secrets Access ----------------
resource "aws_iam_policy" "secrets" {
  count = var.secrets_arns != null && length(var.secrets_arns) > 0 ? 1 : 0

  name = "${local.name_prefix}-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = var.secrets_arns
    }]
  })
}

resource "aws_iam_role_policy_attachment" "secrets" {
  count      = var.secrets_arns != null && length(var.secrets_arns) > 0 ? 1 : 0
  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.secrets[0].arn
}

# ---------------- CloudWatch Logs ----------------
resource "aws_cloudwatch_log_group" "this" {
  for_each = var.enable_logs ? var.services : {}

  name              = "/ecs/${local.name_prefix}-${each.key}"
  retention_in_days = var.log_retention_days
}

# ---------------- ALB ----------------
resource "aws_lb" "this" {
  count              = var.enable_alb ? 1 : 0
  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  subnets            = var.alb_subnets
  security_groups    = var.alb_security_groups
}

resource "aws_lb_target_group" "this" {
  for_each = var.enable_alb ? var.services : {}

  name        = "${local.name_prefix}-${each.key}-tg"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = each.value.health_check_path
  }
}

# ---------------- HTTP Listener ----------------
resource "aws_lb_listener" "http" {
  count             = var.enable_alb && !var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[keys(var.services)[0]].arn
  }
}

# ---------------- HTTP Redirect (when HTTPS enabled) ----------------
resource "aws_lb_listener" "http_redirect" {
  count             = var.enable_alb && var.enable_https ? 1 : 0
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

# ---------------- HTTPS Listener ----------------
resource "aws_lb_listener" "https" {
  count             = var.enable_alb && var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[keys(var.services)[0]].arn
  }
}

# ---------------- Listener Rules ----------------
resource "aws_lb_listener_rule" "this" {
  for_each = var.enable_alb ? var.services : {}

  listener_arn = var.enable_https ? aws_lb_listener.https[0].arn : aws_lb_listener.http[0].arn
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
}

# ---------------- ECS Task ----------------
resource "aws_ecs_task_definition" "this" {
  for_each = var.services

  family                   = "${local.name_prefix}-${each.key}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name  = each.key
    image = each.value.image

    repositoryCredentials = each.value.repository_credentials != null ? {
      credentialsParameter = each.value.repository_credentials
    } : null

    portMappings = [{
      containerPort = each.value.port
      hostPort      = each.value.port
    }]

    environment = [
      for k, v in each.value.env : {
        name  = k
        value = v
      }
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
        awslogs-group         = aws_cloudwatch_log_group.this[each.key].name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    } : null
  }])
}

# ---------------- ECS Service ----------------
resource "aws_ecs_service" "this" {
  for_each = var.services

  name            = "${local.name_prefix}-${each.key}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  enable_execute_command = var.enable_exec

  deployment_minimum_healthy_percent = var.deployment_min_healthy
  deployment_maximum_percent         = var.deployment_max_percent

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = var.health_check_grace_period

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

  depends_on = [aws_lb_listener.http]
}