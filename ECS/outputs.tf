output "alb_dns" {
  value = var.enable_alb ? aws_lb.this[0].dns_name : null
}

output "services" {
  value = {
    for k, v in aws_ecs_service.this : k => v.name
  }
}