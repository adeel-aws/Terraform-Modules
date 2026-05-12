locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------- Subnet Group ----------------
resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

# ---------------- RDS Instance ----------------
resource "aws_db_instance" "this" {
  identifier = "${local.name_prefix}-db"

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids

  publicly_accessible = false

  multi_az                = var.multi_az
  storage_encrypted       = true
  backup_retention_period = var.backup_retention
  deletion_protection     = var.deletion_protection

  skip_final_snapshot = true

  tags = {
    Name = "${local.name_prefix}-db"
  }
}

# ---------------- OPTIONAL: SSM Parameters ----------------
resource "aws_ssm_parameter" "db_host" {
  count = var.enable_ssm_parameters ? 1 : 0

  name  = "/${local.name_prefix}/db/host"
  type  = "String"
  value = aws_db_instance.this.address

  tags = {
    Name = "${local.name_prefix}-db-host"
  }
}

resource "aws_ssm_parameter" "db_port" {
  count = var.enable_ssm_parameters ? 1 : 0

  name  = "/${local.name_prefix}/db/port"
  type  = "String"
  value = tostring(aws_db_instance.this.port)

  tags = {
    Name = "${local.name_prefix}-db-port"
  }
}

resource "aws_ssm_parameter" "db_name" {
  count = var.enable_ssm_parameters ? 1 : 0

  name  = "/${local.name_prefix}/db/name"
  type  = "String"
  value = aws_db_instance.this.db_name

  tags = {
    Name = "${local.name_prefix}-db-name"
  }
}