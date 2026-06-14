# =============================================================================
# EKS MODULE — outputs.tf
# =============================================================================

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "cluster_version" {
  description = "Kubernetes version on the cluster."
  value       = aws_eks_cluster.this.version
}

output "cluster_endpoint" {
  description = "API server URL. Used to configure the Kubernetes and Helm providers."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64-encoded CA cert. Required by the Kubernetes/Helm provider."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN. Pass to the eks-addons module."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL without https://. Used in IRSA trust policy conditions."
  value       = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
}

output "node_iam_role_arn" {
  description = "Node IAM role ARN. Needed when configuring Karpenter."
  value       = aws_iam_role.node.arn
}

output "node_iam_role_name" {
  description = "Node IAM role name. Use to attach extra policies directly if needed."
  value       = aws_iam_role.node.name
}

output "cluster_iam_role_arn" {
  description = "Cluster IAM role ARN."
  value       = aws_iam_role.cluster.arn
}

output "node_group_ids" {
  description = "Map of node group name to AWS resource ID."
  value       = { for k, v in aws_eks_node_group.this : k => v.id }
}

output "node_group_statuses" {
  description = "Map of node group name to current status."
  value       = { for k, v in aws_eks_node_group.this : k => v.status }
}

output "vpc_id" {
  description = "VPC ID, passed through for downstream modules."
  value       = var.vpc_id
}

output "account_id" {
  description = "AWS account ID. Useful for building ARNs in the addons module."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region the cluster is in."
  value       = data.aws_region.current.name
}
