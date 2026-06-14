output "lb_arn" {
  value = aws_lb.this.arn
}

output "lb_dns_name" {
  value = aws_lb.this.dns_name
}

output "lb_zone_id" {
  value = aws_lb.this.zone_id
}

output "lb_name" {
  value = aws_lb.this.name
}

output "target_group_arns" {
  value = {
    for k, v in aws_lb_target_group.this :
    k => v.arn
  }
}