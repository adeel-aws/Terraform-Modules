output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "ec2_sg_id" {
  value = var.create_ec2_sg ? aws_security_group.ec2_sg[0].id : null
  # value = aws_security_group.ec2_sg.id
}

output "db_sg_id" {
  value = var.enable_nat_gateway ? aws_security_group.db_sg[0].id : null
  # value = aws_security_group.db_sg.id
}

output "nat_gateway_id" {
  value = var.enable_nat_gateway ? aws_nat_gateway.nat[0].id : null
}

output "eip_id" {
  value = var.enable_nat_gateway && var.create_eip ? aws_eip.nat[0].id : null
}