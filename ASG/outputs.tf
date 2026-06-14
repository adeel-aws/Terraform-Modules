output "asg_name" {
  value = aws_autoscaling_group.this.name
}

output "asg_arn" {
  value = aws_autoscaling_group.this.arn
}

output "launch_template_id" {
  value = aws_launch_template.this.id
}

output "launch_template_latest_version" {
  value = aws_launch_template.this.latest_version
}

output "ec2_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2.arn
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = aws_iam_instance_profile.ec2.name
}