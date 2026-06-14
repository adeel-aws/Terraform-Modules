# =============================================================================
# EKS MODULE — variables.tf
# =============================================================================

# -----------------------------------------------------------------------------
# CLUSTER
# -----------------------------------------------------------------------------
variable "project_name" {
  description = "Project name used for naming resources."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod, etc.)."
  type        = string
}
# variable "cluster_name" {
#   description = "Cluster name. Used as prefix for every resource this module creates."
#   type        = string

#   validation {
#     condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
#     error_message = "Must start with a letter, only letters/numbers/hyphens allowed."
#   }
# }

variable "kubernetes_version" {
  description = "Kubernetes version. Example: \"1.30\""
  type        = string
  default     = "1.30"
}

variable "tags" {
  description = "Tags applied to every resource this module creates."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# NETWORKING
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID. Informational — passed through to outputs for downstream modules."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the EKS control plane ENIs. Must span at least 2 AZs. Reference: module.vpc.private_subnet_ids"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subnets for worker nodes. Defaults to subnet_ids if empty. Reference: module.vpc.private_subnet_ids"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# SECURITY GROUPS
# Created outside this module (VPC module or root), passed in as IDs.
# This module attaches them — it creates no SG rules itself.
# -----------------------------------------------------------------------------

variable "cluster_sg_ids" {
  description = <<-EOT
    Security group IDs to attach to the EKS control plane.
    Create these in your VPC module or root and pass the IDs here.
    Example: [module.vpc.cluster_sg_id]
  EOT
  type    = list(string)
  default = []
}

variable "node_sg_ids" {
  description = <<-EOT
    Security group IDs to attach to worker nodes.
    Create these in your VPC module or root and pass the IDs here.
    Example: [module.vpc.node_sg_id]
  EOT
  type    = list(string)
  default = []
}

# -----------------------------------------------------------------------------
# API SERVER ACCESS
# -----------------------------------------------------------------------------

variable "endpoint_public_access" {
  description = "Allow the API server to be reached from the public internet. Disable in production."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Allow the API server to be reached from within the VPC."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public endpoint. Restrict to your VPN/office IPs in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# -----------------------------------------------------------------------------
# LOGGING
# -----------------------------------------------------------------------------

variable "enabled_log_types" {
  description = "Control plane log types sent to CloudWatch. Enable all five in production."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]

  validation {
    condition = alltrue([
      for t in var.enabled_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], t)
    ])
    error_message = "Valid values: api, audit, authenticator, controllerManager, scheduler."
  }
}

# -----------------------------------------------------------------------------
# NODE GROUPS
# -----------------------------------------------------------------------------

variable "node_groups" {
  description = <<-EOT
    Map of node group definitions. Each key is the group name.

    capacity_type : ON_DEMAND | SPOT
    ami_type      : AL2_x86_64 | AL2_x86_64_GPU | AL2_ARM_64 | BOTTLEROCKET_x86_64

    Example:
    node_groups = {
      general = {
        instance_types  = ["t3.medium"]
        ami_type        = "AL2_x86_64"
        capacity_type   = "ON_DEMAND"
        disk_size       = 30
        desired_size    = 2
        min_size        = 1
        max_size        = 5
        max_unavailable = 1
        labels          = { role = "general" }
        taints          = []
      }
      spot = {
        instance_types  = ["t3.large", "t3a.large"]
        ami_type        = "AL2_x86_64"
        capacity_type   = "SPOT"
        disk_size       = 30
        desired_size    = 1
        min_size        = 0
        max_size        = 10
        max_unavailable = 1
        labels          = { role = "spot" }
        taints          = [{ key = "spot", value = "true", effect = "NO_SCHEDULE" }]
      }
    }
  EOT
  type = map(object({
    instance_types  = list(string)
    ami_type        = string
    capacity_type   = string
    disk_size       = number
    desired_size    = number
    min_size        = number
    max_size        = number
    max_unavailable = number
    labels          = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))

  default = {
    default = {
      instance_types  = ["t3.medium"]
      ami_type        = "AL2_x86_64"
      capacity_type   = "ON_DEMAND"
      disk_size       = 20
      desired_size    = 2
      min_size        = 1
      max_size        = 4
      max_unavailable = 1
      labels          = {}
      taints          = []
    }
  }
}

# -----------------------------------------------------------------------------
# NODE IAM — TOGGLEABLE POLICIES
# Each flag adds a specific AWS permission to the node role.
# Use the most specific scope possible (pass ARNs) rather than wildcards.
# -----------------------------------------------------------------------------

variable "enable_ssm_access" {
  description = "Attach AmazonSSMManagedInstanceCore — allows shelling into nodes via SSM without a bastion."
  type        = bool
  default     = false
}

variable "enable_cloudwatch_access" {
  description = "Attach CloudWatchAgentServerPolicy — required for Container Insights and custom metrics."
  type        = bool
  default     = false
}

variable "enable_secretsmanager_access" {
  description = "Allow nodes to read from Secrets Manager. Scope with secretsmanager_arns for least privilege."
  type        = bool
  default     = false
}

variable "secretsmanager_arns" {
  description = <<-EOT
    Specific Secrets Manager ARNs nodes are allowed to read.
    If empty and enable_secretsmanager_access = true, access is granted to all secrets in the account.
    Example: ["arn:aws:secretsmanager:us-east-1:123456789:secret:myapp/*"]
  EOT
  type    = list(string)
  default = []
}

variable "enable_ssm_parameter_access" {
  description = "Allow nodes to read from SSM Parameter Store. Scope with ssm_parameter_arns for least privilege."
  type        = bool
  default     = false
}

variable "ssm_parameter_arns" {
  description = <<-EOT
    Specific SSM Parameter Store ARNs nodes are allowed to read.
    If empty and enable_ssm_parameter_access = true, access is granted to all parameters in the account.
    Example: ["arn:aws:ssm:us-east-1:123456789:parameter/myapp/*"]
  EOT
  type    = list(string)
  default = []
}

variable "enable_s3_access" {
  description = "Allow nodes to access S3. Define actions and bucket ARNs for least privilege."
  type        = bool
  default     = false
}

variable "s3_bucket_arns" {
  description = <<-EOT
    S3 bucket ARNs (and optionally prefixes) nodes are allowed to access.
    Include both the bucket and its objects.
    Example: ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"]
  EOT
  type    = list(string)
  default = []
}

variable "s3_access_actions" {
  description = "S3 actions allowed on s3_bucket_arns. Default is read-only."
  type        = list(string)
  default     = ["s3:GetObject", "s3:ListBucket"]
}

variable "node_extra_policy_arns" {
  description = "Any additional existing IAM policy ARNs to attach to the node role not covered by the toggles above."
  type        = list(string)
  default     = []
}
