# =============================================================================
# EKS MODULE
#
# Responsibility: cluster, nodes, IAM, OIDC.
# NOT responsible for: security group rules, add-ons.
#
# Security groups are created outside (VPC module or root) and passed in as IDs.
# Add-ons live in the eks-addons module.

locals {
  name_prefix   = "${var.project_name}-${var.environment}"
  cluster_name  = "${local.name_prefix}-eks"
}

# =============================================================================

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# =============================================================================
# IAM — CLUSTER ROLE
# The control plane assumes this role to manage AWS resources (ENIs, etc.)
# =============================================================================

data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name = "${local.name_prefix}-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_controller" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# =============================================================================
# IAM — NODE ROLE
# EC2 worker nodes assume this role to join the cluster and communicate with AWS.
# Includes optional toggleable policies for secrets, SSM, CloudWatch, S3, ECR.
# =============================================================================

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name = "${local.name_prefix}-node-role"

  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-node-role"
  })
}

# --- Always required ---

resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ecr_readonly" {
  # Allows nodes to pull images from any ECR repo in this account
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# --- Optional: SSM Session Manager (shell into nodes without a bastion) ---

resource "aws_iam_role_policy_attachment" "node_ssm" {
  count      = var.enable_ssm_access ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

# --- Optional: CloudWatch Container Insights ---

resource "aws_iam_role_policy_attachment" "node_cloudwatch" {
  count      = var.enable_cloudwatch_access ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node.name
}

# --- Optional: Secrets Manager (pods that need to read secrets directly) ---

resource "aws_iam_policy" "node_secrets" {
  count       = var.enable_secretsmanager_access ? 1 : 0
  name = "${local.name_prefix}-node-secrets-policy"
  description = "Allow nodes to read Secrets Manager secrets for cluster ${local.cluster_name}"
  tags = merge(var.tags, {
  Name = "${local.name_prefix}-node-secrets-policy"
})

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = length(var.secretsmanager_arns) > 0 ? var.secretsmanager_arns : ["arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_secrets" {
  count      = var.enable_secretsmanager_access ? 1 : 0
  policy_arn = aws_iam_policy.node_secrets[0].arn
  role       = aws_iam_role.node.name
}

# --- Optional: SSM Parameter Store ---

resource "aws_iam_policy" "node_ssm_params" {
  count       = var.enable_ssm_parameter_access ? 1 : 0
  name = "${local.name_prefix}-node-ssm-params-policy"
  description = "Allow nodes to read SSM Parameter Store for cluster ${local.cluster_name}"
  tags = merge(var.tags, {
  Name = "${local.name_prefix}-node-ssm-params-policy"
})

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
      Resource = length(var.ssm_parameter_arns) > 0 ? var.ssm_parameter_arns : ["arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_ssm_params" {
  count      = var.enable_ssm_parameter_access ? 1 : 0
  policy_arn = aws_iam_policy.node_ssm_params[0].arn
  role       = aws_iam_role.node.name
}

# --- Optional: S3 access ---

resource "aws_iam_policy" "node_s3" {
  count       = var.enable_s3_access ? 1 : 0
  name = "${local.name_prefix}-node-s3-policy"
  description = "Allow nodes to access S3 for cluster ${local.cluster_name}"
  tags = merge(var.tags, {
  Name = "${local.name_prefix}-node-s3-policy"
})

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = var.s3_access_actions
      Resource = var.s3_bucket_arns
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_s3" {
  count      = var.enable_s3_access ? 1 : 0
  policy_arn = aws_iam_policy.node_s3[0].arn
  role       = aws_iam_role.node.name
}

# --- Catch-all: any extra existing policy ARNs the caller wants attached ---

resource "aws_iam_role_policy_attachment" "node_extra" {
  for_each   = toset(var.node_extra_policy_arns)
  policy_arn = each.value
  role       = aws_iam_role.node.name
}

# =============================================================================
# EKS CONTROL PLANE
# Security groups are passed in — this module creates none.
# =============================================================================

resource "aws_eks_cluster" "this" {
  name = local.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.cluster_sg_ids   # passed in from VPC module or root
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.public_access_cidrs
  }

  enabled_cluster_log_types = var.enabled_log_types

  tags = merge(var.tags, {
  Name = "${local.name_prefix}-cluster"
})

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_controller,
  ]
}

# =============================================================================
# OIDC PROVIDER
# Required for IRSA (pods assuming IAM roles without node-level credentials).
# The addons module uses the ARN output to create per-addon service account roles.
# =============================================================================

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  tags = merge(var.tags, {
  Name = "${local.name_prefix}-oidc-provider"
})
}

# =============================================================================
# MANAGED NODE GROUPS
# Fully driven by var.node_groups — supports any number of groups.
# Node SGs are passed in — this module creates none.
# =============================================================================

resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = length(var.node_subnet_ids) > 0 ? var.node_subnet_ids : var.subnet_ids

  ami_type       = each.value.ami_type
  instance_types = each.value.instance_types
  disk_size      = each.value.disk_size
  capacity_type  = each.value.capacity_type

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  update_config {
    max_unavailable = each.value.max_unavailable
  }

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # Attach node SGs passed in by the caller
  dynamic "remote_access" {
    for_each = length(var.node_sg_ids) > 0 ? [1] : []
    content {
      source_security_group_ids = var.node_sg_ids
    }
  }

  tags = merge(var.tags, {
  Name      = "${local.name_prefix}-${each.key}-nodegroup"
  NodeGroup = each.key
})

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr_readonly,
  ]

  lifecycle {
    # Autoscaler manages desired_size at runtime.
    # Without this, terraform apply would reset it on every run.
    ignore_changes = [scaling_config[0].desired_size]
  }
}
