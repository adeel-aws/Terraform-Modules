# =============================================================================
# EKS-ADDONS MODULE — variables.tf
# =============================================================================

# -----------------------------------------------------------------------------
# CLUSTER IDENTITY — from eks module outputs
# -----------------------------------------------------------------------------
variable "project_name" {
  description = "Project name used for naming resources."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod, etc.)."
  type        = string
}
variable "cluster_name" {
  description = "EKS cluster name. Reference: module.eks.cluster_name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA. Reference: module.eks.oidc_provider_arn"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL without https://. Reference: module.eks.oidc_provider_url"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID. Reference: module.eks.vpc_id"
  type        = string
}

variable "aws_region" {
  description = "AWS region. Reference: module.eks.aws_region"
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM resources created by this module."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# AWS MANAGED ADD-ONS — toggle + optional version pin
# Leave version as null to get the default for your cluster's K8s version.
# -----------------------------------------------------------------------------

variable "enable_vpc_cni" {
  description = "Install vpc-cni managed add-on. Assigns real VPC IPs to pods. Almost always true."
  type        = bool
  default     = true
}

variable "vpc_cni_version" {
  description = "vpc-cni version. null = AWS default for your K8s version."
  type        = string
  default     = null
}

variable "enable_coredns" {
  description = "Install coredns managed add-on. DNS resolution inside the cluster. Almost always true."
  type        = bool
  default     = true
}

variable "coredns_version" {
  description = "coredns version. null = AWS default."
  type        = string
  default     = null
}

variable "enable_kube_proxy" {
  description = "Install kube-proxy managed add-on. Pod network routing. Almost always true."
  type        = bool
  default     = true
}

variable "kube_proxy_version" {
  description = "kube-proxy version. null = AWS default."
  type        = string
  default     = null
}

variable "enable_ebs_csi" {
  description = "Install aws-ebs-csi-driver. Enable when pods need persistent EBS volumes (StatefulSets, databases)."
  type        = bool
  default     = false
}

variable "ebs_csi_version" {
  description = "aws-ebs-csi-driver version. null = AWS default."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# HELM ADD-ONS — toggle + optional version pin
# -----------------------------------------------------------------------------

variable "enable_metrics_server" {
  description = "Install metrics-server. Required for HorizontalPodAutoscaler to work."
  type        = bool
  default     = false
}

variable "metrics_server_version" {
  description = "metrics-server Helm chart version. null = latest."
  type        = string
  default     = null
}

variable "enable_alb_controller" {
  description = "Install AWS Load Balancer Controller. Required for Ingress resources to create ALBs."
  type        = bool
  default     = false
}

variable "alb_controller_version" {
  description = "aws-load-balancer-controller Helm chart version."
  type        = string
  default     = "1.8.1"
}

variable "enable_cluster_autoscaler" {
  description = "Install Cluster Autoscaler. Scales node count based on pending pods. Use this OR Karpenter, not both."
  type        = bool
  default     = false
}

variable "cluster_autoscaler_version" {
  description = "cluster-autoscaler Helm chart version."
  type        = string
  default     = "9.37.0"
}

variable "enable_external_secrets" {
  description = "Install External Secrets Operator. Syncs Secrets Manager values into K8s Secret objects."
  type        = bool
  default     = false
}

variable "external_secrets_version" {
  description = "external-secrets Helm chart version."
  type        = string
  default     = "0.10.0"
}

variable "external_secrets_sm_arns" {
  description = <<-EOT
    Secrets Manager ARNs the External Secrets Operator is allowed to read.
    Scope this tightly — don't leave it as wildcard in production.
    Example: ["arn:aws:secretsmanager:us-east-1:123456789:secret:myapp/*"]
  EOT
  type    = list(string)
  default = []
}

variable "enable_cert_manager" {
  description = "Install cert-manager. Provisions and renews TLS certs automatically."
  type        = bool
  default     = false
}

variable "cert_manager_version" {
  description = "cert-manager Helm chart version."
  type        = string
  default     = "v1.15.0"
}
