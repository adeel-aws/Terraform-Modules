resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type

  ttl     = lookup(each.value, "ttl", null)
  records = lookup(each.value, "records", null)

  # -------------------------
  # ALIAS SUPPORT (ALB / NLB / CLOUDFRONT)
  # -------------------------
  dynamic "alias" {
    for_each = lookup(each.value, "alias", null) != null ? [1] : []

    content {
      name                   = each.value.alias.name
      zone_id                = each.value.alias.zone_id
      evaluate_target_health = lookup(each.value.alias, "evaluate_target_health", false)
    }
  }

  # -------------------------
  # ROUTING POLICIES
  # -------------------------

  # Weighted Routing
  dynamic "weighted_routing_policy" {
    for_each = lookup(each.value, "weighted_routing_policy", null) != null ? [1] : []

    content {
      weight = each.value.weighted_routing_policy.weight
    }
  }

  # Failover Routing
  dynamic "failover_routing_policy" {
    for_each = lookup(each.value, "failover_routing_policy", null) != null ? [1] : []

    content {
      type = each.value.failover_routing_policy.type
    }
  }

  # Latency Routing
  dynamic "latency_routing_policy" {
    for_each = lookup(each.value, "latency_routing_policy", null) != null ? [1] : []

    content {
      region = each.value.latency_routing_policy.region
    }
  }

  # Optional identifier (required for routing policies)
  set_identifier = lookup(each.value, "set_identifier", null)
}