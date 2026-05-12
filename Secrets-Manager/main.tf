locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_secretsmanager_secret" "this" {
  name                    = "${local.name_prefix}-${var.name}"
  description             = var.description
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name = "${local.name_prefix}-${var.name}"
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id

  secret_string = jsonencode(var.secret_map)
}