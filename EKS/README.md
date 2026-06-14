# Module: `eks`

Reusable EKS module. Provisions the cluster, nodes, IAM, and networking.
Add-ons (ALB controller, External Secrets, etc.) live in the separate `eks-addons` module.

---

## What this creates

| Resource | Purpose |
|---|---|
| IAM role — cluster | Lets the control plane call AWS APIs |
| IAM role — node | Lets EC2 workers join the cluster and pull from ECR |
| Security group — cluster | Controls traffic to/from the control plane |
| Security group — node | Controls traffic to/from worker nodes |
| `aws_eks_cluster` | The EKS control plane |
| `aws_iam_openid_connect_provider` | OIDC provider — required for IRSA |
| `aws_eks_node_group` (× N) | One per entry in `var.node_groups` |

---

## Usage examples

### Dev — minimal, single node group

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name       = "myapp-dev"
  kubernetes_version = "1.30"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids

  tags = { Project = "myapp", Env = "dev" }
}
```

### Production — private API, restricted access, multiple node groups

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name            = "myapp-prod"
  kubernetes_version      = "1.30"
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnet_ids
  node_subnet_ids         = module.vpc.private_subnet_ids
  endpoint_public_access  = false
  endpoint_private_access = true
  public_access_cidrs     = []
  enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  node_groups = {
    general = {
      instance_types  = ["t3.medium"]
      ami_type        = "AL2_x86_64"
      capacity_type   = "ON_DEMAND"
      disk_size       = 30
      desired_size    = 2
      min_size        = 2
      max_size        = 6
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
      taints = [
        { key = "spot", value = "true", effect = "NO_SCHEDULE" }
      ]
    }
  }

  # Allow ALB security group to reach nodes on port 8080
  node_extra_ingress_rules = [
    {
      description  = "ALB to nodes"
      from_port    = 8080
      to_port      = 8080
      protocol     = "tcp"
      source_sg_id = module.alb.security_group_id
    }
  ]

  # Attach existing SG (e.g. a shared VPN group) to the control plane
  extra_cluster_security_group_ids = [aws_security_group.vpn.id]

  # Allow nodes to reach SSM and internal services only
  node_egress_cidrs = ["10.0.0.0/8"]

  node_extra_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  tags = { Project = "myapp", Env = "prod", ManagedBy = "terraform" }
}
```

### Wire up Kubernetes and Helm providers using outputs

```hcl
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

### Pass outputs to eks-addons module

```hcl
module "eks_addons" {
  source = "./modules/eks-addons"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  vpc_id            = module.eks.vpc_id
  node_sg_id        = module.eks.node_security_group_id
}
```

---

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | `string` | required | Cluster name, used as prefix for all resources |
| `kubernetes_version` | `string` | `"1.30"` | Kubernetes version |
| `vpc_id` | `string` | required | VPC to deploy into |
| `subnet_ids` | `list(string)` | required | Subnets for control plane (min 2 AZs) |
| `node_subnet_ids` | `list(string)` | `[]` | Subnets for nodes (defaults to subnet_ids) |
| `extra_cluster_security_group_ids` | `list(string)` | `[]` | Existing SGs to attach to control plane |
| `cluster_egress_cidrs` | `list(string)` | `["0.0.0.0/0"]` | Outbound CIDRs for control plane |
| `node_egress_cidrs` | `list(string)` | `["0.0.0.0/0"]` | Outbound CIDRs for nodes |
| `node_to_node_port_range` | `list(number)` | `[0, 65535]` | Port range for node-to-node traffic |
| `cluster_to_node_port_range` | `list(number)` | `[1025, 65535]` | Port range for control plane → nodes |
| `node_extra_ingress_rules` | `list(object)` | `[]` | Extra ingress rules for the node SG |
| `endpoint_public_access` | `bool` | `true` | Allow public API access |
| `endpoint_private_access` | `bool` | `true` | Allow private API access |
| `public_access_cidrs` | `list(string)` | `["0.0.0.0/0"]` | CIDRs allowed on public endpoint |
| `enabled_log_types` | `list(string)` | `["api","audit","authenticator"]` | Control plane log types |
| `node_groups` | `map(object)` | single `default` group | Node group definitions |
| `node_extra_policy_arns` | `list(string)` | `[]` | Extra IAM policies for node role |
| `tags` | `map(string)` | `{}` | Tags on all resources |

---

## Outputs

| Name | Description |
|---|---|
| `cluster_name` | Cluster name |
| `cluster_arn` | Cluster ARN |
| `cluster_version` | Kubernetes version |
| `cluster_endpoint` | API server URL |
| `cluster_certificate_authority` | Base64 CA cert (sensitive) |
| `oidc_provider_arn` | OIDC ARN — pass to eks-addons |
| `oidc_provider_url` | OIDC URL without https:// |
| `cluster_security_group_id` | Control plane SG ID |
| `node_security_group_id` | Node SG ID |
| `cluster_iam_role_arn` | Cluster IAM role ARN |
| `node_iam_role_arn` | Node IAM role ARN |
| `node_iam_role_name` | Node IAM role name |
| `node_group_ids` | Map of group name → resource ID |
| `node_group_statuses` | Map of group name → status |
| `vpc_id` | VPC ID (passed through) |

---

## Configure kubectl

```bash
aws eks update-kubeconfig --region <region> --name <cluster_name>
kubectl get nodes
```

---

## Key design decisions

**Add-ons are NOT in this module.** AWS managed add-ons (vpc-cni, coredns, etc.) and third-party add-ons (ALB controller, External Secrets) all live in `eks-addons`. This module only creates the cluster and nodes.

**`desired_size` is ignored after first apply.** The `lifecycle { ignore_changes }` block prevents Terraform from fighting Cluster Autoscaler or Karpenter, which adjust node count at runtime.

**Security group rules are fully variable-driven.** No port numbers or CIDRs are hardcoded. Use `node_extra_ingress_rules` to allow ALB, VPN, or monitoring traffic without modifying the module.

**`node_subnet_ids` falls back to `subnet_ids`.** So you only need one variable for simple setups, but can split control-plane subnets from node subnets for stricter network segmentation.
