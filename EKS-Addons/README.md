# Module: `eks-addons`

Installs add-ons into an existing EKS cluster. Always called after the `eks` module —
it takes the EKS module's outputs as inputs and creates nothing in AWS infrastructure itself,
only IAM roles and Kubernetes/Helm resources.

---

## Two categories of add-ons

**AWS Managed** — AWS owns, versions, and patches these. Enabled via `aws_eks_addon`.

| Add-on | Toggle | When you need it |
|---|---|---|
| vpc-cni | `enable_vpc_cni` | Always — assigns real VPC IPs to pods |
| coredns | `enable_coredns` | Always — DNS resolution inside cluster |
| kube-proxy | `enable_kube_proxy` | Always — pod network routing |
| aws-ebs-csi-driver | `enable_ebs_csi` | When pods need persistent EBS volumes |

**Helm / External** — community or AWS-maintained Helm charts. Each one that calls AWS APIs also gets an IRSA role created automatically.

| Add-on | Toggle | When you need it |
|---|---|---|
| metrics-server | `enable_metrics_server` | Required for HPA (pod autoscaling) |
| aws-load-balancer-controller | `enable_alb_controller` | Required for Ingress to create ALBs |
| cluster-autoscaler | `enable_cluster_autoscaler` | Scales node count automatically |
| external-secrets | `enable_external_secrets` | Syncs Secrets Manager → K8s Secrets |
| cert-manager | `enable_cert_manager` | Auto-provisions TLS certificates |

---

## Required providers at root

```hcl
terraform {
  required_providers {
    aws        = { source = "hashicorp/aws" }
    helm       = { source = "hashicorp/helm" }
    kubernetes = { source = "hashicorp/kubernetes" }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}
```

---

## Usage — minimal (just the three core add-ons)

```hcl
module "eks_addons" {
  source = "./modules/eks-addons"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  vpc_id            = module.eks.vpc_id
  aws_region        = module.eks.aws_region

  # Three core add-ons on by default (vpc-cni, coredns, kube-proxy)
  # Nothing else enabled

  tags = { Project = "myapp", Env = "dev" }

  depends_on = [module.eks]
}
```

## Usage — three-tier web application

```hcl
module "eks_addons" {
  source = "./modules/eks-addons"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  vpc_id            = module.eks.vpc_id
  aws_region        = module.eks.aws_region

  # Core
  enable_vpc_cni    = true
  enable_coredns    = true
  enable_kube_proxy = true

  # Persistent storage for DB pods
  enable_ebs_csi    = true

  # ALB for Ingress
  enable_alb_controller = true

  # Pod autoscaling
  enable_metrics_server = true

  # Node autoscaling
  enable_cluster_autoscaler = true

  # Pull DB password and JWT secret from Secrets Manager
  enable_external_secrets  = true
  external_secrets_sm_arns = [
    "arn:aws:secretsmanager:us-east-1:123456789:secret:myapp/prod/*"
  ]

  tags = { Project = "myapp", Env = "prod" }

  depends_on = [module.eks]
}
```

---

## How the two modules connect at root

```hcl
# 1. Create cluster
module "eks" {
  source = "./modules/eks"

  cluster_name    = "myapp-prod"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  cluster_sg_ids  = [module.vpc.cluster_sg_id]
  node_sg_ids     = [module.vpc.node_sg_id]

  enable_ssm_access            = true
  enable_secretsmanager_access = true
  secretsmanager_arns          = ["arn:aws:secretsmanager:us-east-1:123456789:secret:myapp/*"]
}

# 2. Install add-ons — explicit depends_on ensures cluster is fully ready
module "eks_addons" {
  source = "./modules/eks-addons"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  vpc_id            = module.eks.vpc_id
  aws_region        = module.eks.aws_region

  enable_alb_controller     = true
  enable_metrics_server     = true
  enable_cluster_autoscaler = true
  enable_external_secrets   = true

  depends_on = [module.eks]
}
```

---

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | `string` | required | From `module.eks.cluster_name` |
| `oidc_provider_arn` | `string` | required | From `module.eks.oidc_provider_arn` |
| `oidc_provider_url` | `string` | required | From `module.eks.oidc_provider_url` |
| `vpc_id` | `string` | required | From `module.eks.vpc_id` |
| `aws_region` | `string` | required | From `module.eks.aws_region` |
| `enable_vpc_cni` | `bool` | `true` | |
| `enable_coredns` | `bool` | `true` | |
| `enable_kube_proxy` | `bool` | `true` | |
| `enable_ebs_csi` | `bool` | `false` | |
| `enable_metrics_server` | `bool` | `false` | |
| `enable_alb_controller` | `bool` | `false` | |
| `enable_cluster_autoscaler` | `bool` | `false` | |
| `enable_external_secrets` | `bool` | `false` | |
| `external_secrets_sm_arns` | `list(string)` | `[]` | Scope to specific secrets in prod |
| `enable_cert_manager` | `bool` | `false` | |
| `tags` | `map(string)` | `{}` | |

---

## Outputs

| Name | Description |
|---|---|
| `alb_controller_role_arn` | IRSA role for ALB controller |
| `cluster_autoscaler_role_arn` | IRSA role for Cluster Autoscaler |
| `external_secrets_role_arn` | IRSA role for External Secrets |
| `ebs_csi_role_arn` | IRSA role for EBS CSI driver |
