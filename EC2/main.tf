locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------- IAM Role (SSM optional) ----------------
resource "aws_iam_role" "ssm_role" {
  count = var.enable_ssm ? 1 : 0

  name = "${local.name_prefix}-${var.instance_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  count = var.enable_ssm ? 1 : 0

  name = "${local.name_prefix}-${var.instance_name}-ssm-profile"
  role = aws_iam_role.ssm_role[0].name
}

# ---------------- EC2 Instance ----------------
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name != "" ? var.key_name : null

  iam_instance_profile = var.enable_ssm ? aws_iam_instance_profile.ssm_profile[0].name : null

  user_data = var.user_data != "" ? var.user_data : null

  # ---------------- Security: IMDSv2 ----------------
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  # ---------------- Root volume (optional upgrade) ----------------
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = var.enable_volume_encryption
    delete_on_termination = true
  }

  monitoring = var.enable_detailed_monitoring

  tags = merge({
    Name        = "${var.instance_name}-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }, var.tags)
}

# ---------------- Optional Elastic IP ----------------
resource "aws_eip" "this" {
  count    = var.enable_eip ? 1 : 0
  instance = aws_instance.this.id
  domain   = "vpc"

  tags = {
    Name = "${local.name_prefix}-${var.instance_name}-eip"
  }
}