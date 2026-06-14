# =============================================================================
# EKS-ADDONS MODULE — outputs.tf
# =============================================================================

output "alb_controller_role_arn" {
  description = "IAM role ARN used by the ALB controller. Reference in annotation if needed outside this module."
  value       = var.enable_alb_controller ? aws_iam_role.alb_controller[0].arn : null
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN used by Cluster Autoscaler."
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : null
}

output "external_secrets_role_arn" {
  description = "IAM role ARN used by External Secrets Operator."
  value       = var.enable_external_secrets ? aws_iam_role.external_secrets[0].arn : null
}

output "ebs_csi_role_arn" {
  description = "IAM role ARN used by the EBS CSI driver."
  value       = var.enable_ebs_csi ? aws_iam_role.ebs_csi[0].arn : null
}
