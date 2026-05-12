output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "elb_sg_id" {
  value = var.create_elb_sg ? aws_security_group.elb_sg[0].id : null
}

output "app_sg_id" {
  value = var.create_app_sg ? aws_security_group.app_sg[0].id : null
}

output "db_sg_id" {
  value = var.create_db_sg ? aws_security_group.db_sg[0].id : null
}

output "nat_gateway_id" {
  value = var.enable_nat_gateway ? aws_nat_gateway.nat[0].id : null
}