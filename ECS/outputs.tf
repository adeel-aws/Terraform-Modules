output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "service_names" {
  description = "Map of service key → ECS service name"
  value       = { for k, v in aws_ecs_service.this : k => v.name }
}

output "task_definition_arns" {
  description = "Map of service key → task definition ARN"
  value       = { for k, v in aws_ecs_task_definition.this : k => v.arn }
}

output "alb_dns_name" {
  description = "ALB DNS name — use as CloudFront custom origin domain"
  value       = var.enable_alb ? aws_lb.this[0].dns_name : null
}

output "alb_arn" {
  description = "ALB ARN"
  value       = var.enable_alb ? aws_lb.this[0].arn : null
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix — used in request-count autoscaling resource_label"
  value       = var.enable_alb ? aws_lb.this[0].arn_suffix : null
}

output "target_group_arns" {
  description = "Map of service key → target group ARN"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "execution_role_arn" {
  description = "ECS execution role ARN"
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.task.arn
}

output "log_group_names" {
  description = "Map of service key → CloudWatch log group name"
  value       = { for k, v in aws_cloudwatch_log_group.this : k => v.name }
}
