locals {
  name_prefix = "${var.project_name}-${var.environment}"

  target_groups = var.target_groups

  is_alb = lower(var.lb_type) == "application"
  is_nlb = lower(var.lb_type) == "network"

  target_group_attachments = flatten([
    for tg_key, tg in var.target_groups : [
      for id in lookup(tg, "target_ids", []) : {
        key    = "${tg_key}-${id}"
        tg_key = tg_key
        id     = id
      }
    ]
  ])
}

# ---------------------------------------------------------
# LOAD BALANCER
# ---------------------------------------------------------
resource "aws_lb" "this" {

  name               = "${local.name_prefix}-${var.name}-lb"
  load_balancer_type = var.lb_type

  internal = var.internal

  subnets = var.subnet_ids

  security_groups = length(var.security_group_ids) > 0 ? var.security_group_ids : null

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  idle_timeout               = local.is_alb ? var.idle_timeout : null
  drop_invalid_header_fields = local.is_alb ? var.drop_invalid_header_fields : null

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []

    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${var.name}-lb"
  })
}

# ---------------------------------------------------------
# OPTIONAL WAF ASSOCIATION
# ---------------------------------------------------------
resource "aws_wafv2_web_acl_association" "this" {

  count = (
    local.is_alb &&
    var.enable_waf
  ) ? 1 : 0

  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_acl_arn
}

# ---------------------------------------------------------
# TARGET GROUPS
# ---------------------------------------------------------
resource "aws_lb_target_group" "this" {

  for_each = local.target_groups

  name        = "${local.name_prefix}-${each.key}-tg"
  port        = each.value.port
  protocol    = upper(each.value.protocol)
  target_type = lookup(each.value, "target_type", "instance")

  vpc_id = var.vpc_id

  deregistration_delay = lookup(each.value, "deregistration_delay", 300)

  slow_start = local.is_alb ? lookup(each.value, "slow_start", 0) : null

  load_balancing_algorithm_type = local.is_alb ? lookup(each.value, "load_balancing_algorithm_type", "round_robin") : null

  proxy_protocol_v2 = local.is_nlb ? lookup(each.value, "proxy_protocol_v2", false) : null

  dynamic "health_check" {
    for_each = [1]

    content {

      enabled = lookup(each.value, "health_check_enabled", true)

      path = contains(
        ["HTTP", "HTTPS"],
        upper(lookup(each.value, "health_check_protocol", each.value.protocol))
      ) ? lookup(each.value, "health_check_path", "/") : null

      port = lookup(each.value, "health_check_port", "traffic-port")

      protocol = upper(
        lookup(each.value, "health_check_protocol", each.value.protocol)
      )

      interval = lookup(each.value, "health_check_interval", 30)

      timeout = lookup(each.value, "health_check_timeout", 5)

      healthy_threshold = lookup(each.value, "healthy_threshold", 2)

      unhealthy_threshold = lookup(each.value, "unhealthy_threshold", 2)

      matcher = contains(
        ["HTTP", "HTTPS"],
        upper(lookup(each.value, "health_check_protocol", each.value.protocol))
      ) ? lookup(each.value, "matcher", "200-399") : null
    }
  }

  dynamic "stickiness" {
    for_each = (
      local.is_alb &&
      lookup(each.value, "enable_stickiness", false)
    ) ? [1] : []

    content {
      enabled = true
      type    = lookup(each.value, "stickiness_type", "lb_cookie")
    }
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${each.key}-tg"
  })
}

# ---------------------------------------------------------
# HTTP LISTENER (ALB)
# ---------------------------------------------------------
resource "aws_lb_listener" "http" {

  count = (
    local.is_alb &&
    var.enable_http_listener
  ) ? 1 : 0

  load_balancer_arn = aws_lb.this.arn

  port     = var.http_listener_port
  protocol = "HTTP"

  dynamic "default_action" {
    for_each = var.enable_https_redirect ? [1] : []

    content {

      type = "redirect"

      redirect {
        port        = tostring(var.https_listener_port)
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.enable_https_redirect ? [] : [1]

    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[var.default_target_group].arn
    }
  }
}

# ---------------------------------------------------------
# HTTPS LISTENER (ALB)
# ---------------------------------------------------------
resource "aws_lb_listener" "https" {

  count = (
    local.is_alb &&
    var.enable_https_listener
  ) ? 1 : 0

  load_balancer_arn = aws_lb.this.arn

  port     = var.https_listener_port
  protocol = "HTTPS"

  ssl_policy      = var.ssl_policy
  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[var.default_target_group].arn
  }
}

# ---------------------------------------------------------
# TLS LISTENERS (NLB) — multiple ports + target groups
# ---------------------------------------------------------
resource "aws_lb_listener" "tls" {
  for_each = local.is_nlb ? var.tls_listeners : {}

  load_balancer_arn = aws_lb.this.arn

  port            = each.value.port
  protocol        = "TLS"
  certificate_arn = lookup(each.value, "certificate_arn", var.certificate_arn)
  ssl_policy      = lookup(each.value, "ssl_policy", var.ssl_policy)

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.this[
      coalesce(lookup(each.value, "target_group", null), var.default_target_group)
    ].arn
  }
}

# ---------------------------------------------------------
# TCP LISTENERS (NLB) — multiple ports + target groups
# ---------------------------------------------------------
resource "aws_lb_listener" "tcp" {
  for_each = local.is_nlb ? var.tcp_listeners : {}

  load_balancer_arn = aws_lb.this.arn

  port     = each.value.port
  protocol = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.this[
      coalesce(lookup(each.value, "target_group", null), var.default_target_group)
    ].arn
  }
}

# ---------------------------------------------------------
# UDP LISTENERS (NLB) — multiple ports + target groups
# ---------------------------------------------------------
resource "aws_lb_listener" "udp" {
  for_each = local.is_nlb ? var.udp_listeners : {}

  load_balancer_arn = aws_lb.this.arn

  port     = each.value.port
  protocol = "UDP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.this[
      coalesce(lookup(each.value, "target_group", null), var.default_target_group)
    ].arn
  }
}

# ---------------------------------------------------------
# TCP_UDP LISTENERS (NLB) — multiple ports + target groups
# ---------------------------------------------------------
resource "aws_lb_listener" "tcp_udp" {
  for_each = local.is_nlb ? var.tcp_udp_listeners : {}

  load_balancer_arn = aws_lb.this.arn

  port     = each.value.port
  protocol = "TCP_UDP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.this[
      coalesce(lookup(each.value, "target_group", null), var.default_target_group)
    ].arn
  }
}
# ---------------------------------------------------------
# PATH / HOST BASED ROUTING
# ---------------------------------------------------------
resource "aws_lb_listener_rule" "this" {

  for_each = local.is_alb ? {
    for k, v in var.target_groups :
    k => v
    if (
      length(lookup(v, "paths", [])) > 0 ||
      length(lookup(v, "host_headers", [])) > 0
    )
  } : {}

  listener_arn = (
    var.enable_https_listener
    ? aws_lb_listener.https[0].arn
    : aws_lb_listener.http[0].arn
  )

  priority = lookup(
    each.value,
    "priority",
    100 + index(keys(var.target_groups), each.key)
  )

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  dynamic "condition" {
    for_each = length(lookup(each.value, "paths", [])) > 0 ? [1] : []

    content {
      path_pattern {
        values = each.value.paths
      }
    }
  }

  dynamic "condition" {
    for_each = length(lookup(each.value, "host_headers", [])) > 0 ? [1] : []

    content {
      host_header {
        values = each.value.host_headers
      }
    }
  }
}

# ---------------------------------------------------------
# OPTIONAL TARGET ATTACHMENTS
# ---------------------------------------------------------
resource "aws_lb_target_group_attachment" "this" {

  for_each = {
    for item in local.target_group_attachments :
    item.key => item
  }

  target_group_arn = aws_lb_target_group.this[each.value.tg_key].arn

  target_id = each.value.id

  port = local.target_groups[each.value.tg_key].port
}