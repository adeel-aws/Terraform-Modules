# Optional IAM role for SSM
resource "aws_iam_role" "ssm_role" {
  count = var.enable_ssm ? 1 : 0

  name = "${var.instance_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach SSM policy
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  count = var.enable_ssm ? 1 : 0

  role       = aws_iam_role.ssm_role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "ssm_profile" {
  count = var.enable_ssm ? 1 : 0

  name = "${var.instance_name}-ssm-profile"
  role = aws_iam_role.ssm_role[count.index].name
}

# EC2 instance
resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_sg_ids

  # Only attach IAM instance profile if SSM is enabled
  iam_instance_profile = var.enable_ssm ? aws_iam_instance_profile.ssm_profile[0].name : null

  # Optional user_data
  user_data = var.user_data

  tags = {
    Name = var.instance_name
  }
}