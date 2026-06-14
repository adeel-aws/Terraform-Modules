# =============================================================================
# EKS-ADDONS MODULE — main.tf
#
# Installs add-ons into an existing EKS cluster.
# Takes the eks module's outputs as inputs — no cluster resources created here.
#
# Two categories:
#   AWS Managed  — aws_eks_addon resources (vpc-cni, coredns, kube-proxy, ebs-csi)
#   Helm/External — helm_release resources (ALB controller, External Secrets,
#                   Metrics Server, Cluster Autoscaler, cert-manager)
#
# Each add-on is independently toggled. Enable only what your project needs.
# External add-ons that call AWS APIs also get an IRSA role created here.
# =============================================================================

data "aws_partition" "current" {}

# =============================================================================
# IRSA HELPER — reusable trust policy
# Any add-on that needs to call AWS APIs gets its own IAM role.
# The role trusts the cluster's OIDC provider and is scoped to one service account.
# =============================================================================

# Used by every IRSA role below — parameterized per add-on
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  oidc_url = var.oidc_provider_url
  oidc_arn = var.oidc_provider_arn
}

# =============================================================================
# AWS MANAGED ADD-ONS
# AWS owns, versions, and patches these.
# resolve_conflicts_on_update = OVERWRITE so AWS can update config safely.
# =============================================================================

resource "aws_eks_addon" "vpc_cni" {
  count                       = var.enable_vpc_cni ? 1 : 0
  cluster_name                = var.cluster_name
  addon_name                  = "vpc-cni"
  addon_version               = var.vpc_cni_version
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = var.tags
}

resource "aws_eks_addon" "coredns" {
  count                       = var.enable_coredns ? 1 : 0
  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  addon_version               = var.coredns_version
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  count                       = var.enable_kube_proxy ? 1 : 0
  cluster_name                = var.cluster_name
  addon_name                  = "kube-proxy"
  addon_version               = var.kube_proxy_version
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = var.tags
}

resource "aws_eks_addon" "ebs_csi" {
  count                       = var.enable_ebs_csi ? 1 : 0
  cluster_name                = var.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = var.ebs_csi_version
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = var.enable_ebs_csi ? aws_iam_role.ebs_csi[0].arn : null
  tags                        = var.tags
}

# IRSA for EBS CSI driver
data "aws_iam_policy_document" "ebs_csi_trust" {
  count = var.enable_ebs_csi ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  count              = var.enable_ebs_csi ? 1 : 0
  name               = "${local.name_prefix}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_trust[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count      = var.enable_ebs_csi ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi[0].name
}

# =============================================================================
# HELM ADD-ONS — METRICS SERVER
# Feeds CPU/memory data to HPA. Required for pod autoscaling to work.
# =============================================================================

resource "helm_release" "metrics_server" {
  count      = var.enable_metrics_server ? 1 : 0
  name       = "${local.name_prefix}-metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_version
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
}
# =============================================================================
# HELM ADD-ONS — AWS LOAD BALANCER CONTROLLER
# Watches Ingress resources and provisions ALBs automatically.
# Needs IRSA so it can call EC2/ELB/IAM APIs.
# =============================================================================

data "aws_iam_policy_document" "alb_trust" {
  count = var.enable_alb_controller ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  count              = var.enable_alb_controller ? 1 : 0
  name               = "${local.name_prefix}-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_trust[0].json
  tags               = var.tags
}

# AWS publishes the official policy document for the ALB controller
resource "aws_iam_policy" "alb_controller" {
  count       = var.enable_alb_controller ? 1 : 0
  name        = "${local.name_prefix}-alb-controller-policy"
  description = "Policy for AWS Load Balancer Controller on ${local.name_prefix}"
  tags        = var.tags
  policy      = file("${path.module}/policies/alb-controller.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  count      = var.enable_alb_controller ? 1 : 0
  policy_arn = aws_iam_policy.alb_controller[0].arn
  role       = aws_iam_role.alb_controller[0].name
}

resource "helm_release" "alb_controller" {
  count      = var.enable_alb_controller ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.alb_controller_version
  namespace  = "kube-system"

  set { name = "clusterName";                           value = var.cluster_name }
  set { name = "serviceAccount.create";                 value = "true" }
  set { name = "serviceAccount.name";                   value = "aws-load-balancer-controller" }
  set { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"; value = aws_iam_role.alb_controller[0].arn }
  set { name = "vpcId";                                 value = var.vpc_id }
  set { name = "region";                                value = var.aws_region }

  depends_on = [aws_iam_role_policy_attachment.alb_controller]
}

# =============================================================================
# HELM ADD-ONS — CLUSTER AUTOSCALER
# Scales node count up/down based on pending pods and underutilised nodes.
# Alternative to Karpenter — simpler to start with.
# =============================================================================

data "aws_iam_policy_document" "cluster_autoscaler_trust" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  count              = var.enable_cluster_autoscaler ? 1 : 0
  name               = "${local.name_prefix}-cluster-autoscaler-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_trust[0].json
  tags               = var.tags
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count       = var.enable_cluster_autoscaler ? 1 : 0
  name        = "${local.name_prefix}-cluster-autoscaler-policy"
  description = "Policy for Cluster Autoscaler on ${var.cluster_name}"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeImages",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
  role       = aws_iam_role.cluster_autoscaler[0].name
}

resource "helm_release" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.cluster_autoscaler_version
  namespace  = "kube-system"

  set { name = "autoDiscovery.clusterName"; value = var.cluster_name }
  set { name = "awsRegion";                 value = var.aws_region }
  set { name = "rbac.serviceAccount.create";                                          value = "true" }
  set { name = "rbac.serviceAccount.name";                                            value = "cluster-autoscaler" }
  set { name = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn";     value = aws_iam_role.cluster_autoscaler[0].arn }

  depends_on = [aws_iam_role_policy_attachment.cluster_autoscaler]
}

# =============================================================================
# HELM ADD-ONS — EXTERNAL SECRETS OPERATOR
# Syncs secrets from Secrets Manager into Kubernetes Secret objects.
# Pods read a normal K8s Secret — no AWS SDK needed in app code.
# =============================================================================

data "aws_iam_policy_document" "external_secrets_trust" {
  count = var.enable_external_secrets ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  count              = var.enable_external_secrets ? 1 : 0
  name               = "${local.name_prefix}-external-secrets-role"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_trust[0].json
  tags               = var.tags
}

resource "aws_iam_policy" "external_secrets" {
  count       = var.enable_external_secrets ? 1 : 0
  name        = "${local.name_prefix}-external-secrets-policy"
  description = "Allow External Secrets Operator to read from Secrets Manager"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret", "secretsmanager:ListSecretVersionIds"]
      Resource = length(var.external_secrets_sm_arns) > 0 ? var.external_secrets_sm_arns : ["*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  count      = var.enable_external_secrets ? 1 : 0
  policy_arn = aws_iam_policy.external_secrets[0].arn
  role       = aws_iam_role.external_secrets[0].name
}

resource "kubernetes_namespace" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0
  metadata { name = "external-secrets" }
}

resource "helm_release" "external_secrets" {
  count      = var.enable_external_secrets ? 1 : 0
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.external_secrets_version
  namespace  = "external-secrets"

  set { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"; value = aws_iam_role.external_secrets[0].arn }

  depends_on = [
    kubernetes_namespace.external_secrets,
    aws_iam_role_policy_attachment.external_secrets,
  ]
}

# =============================================================================
# HELM ADD-ONS — CERT-MANAGER
# Automatically provisions and renews TLS certificates (ACM or Let's Encrypt).
# =============================================================================

resource "kubernetes_namespace" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0
  metadata { name = "cert-manager" }
}

resource "helm_release" "cert_manager" {
  count      = var.enable_cert_manager ? 1 : 0
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version
  namespace  = "cert-manager"

  set { name = "installCRDs"; value = "true" }

  depends_on = [kubernetes_namespace.cert_manager]
}
