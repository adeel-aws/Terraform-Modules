variable "project_name" {
  description = "Project name — used as prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region (e.g. us-east-1)"
  type        = string
}

# ================================================================
#  NETWORKING
# ================================================================

variable "vpc_id" {
  description = "VPC ID where target groups and services are deployed"
  type        = string
}

variable "subnets" {
  description = "Private subnet IDs for ECS Fargate tasks"
  type        = list(string)
}

variable "security_groups" {
  description = "Security group IDs to attach to ECS tasks"
  type        = list(string)
}

variable "alb_subnets" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "alb_security_groups" {
  description = "Security group IDs to attach to the ALB"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to Fargate tasks (set false when using private subnets + NAT)"
  type        = bool
  default     = false
}

# ================================================================
#  ALB
# ================================================================

variable "enable_alb" {
  description = "Whether to create an ALB for this cluster"
  type        = bool
  default     = true
}

# ================================================================
#  LISTENER MODE
#
#  http_only     — HTTP :80 forward only
#  https_only    — HTTPS :443 forward only (certificate_arn required)
#  http_to_https — HTTP :80 redirects to HTTPS :443 (certificate_arn required)
#  dual          — HTTP :80 forward + HTTPS :443 forward, no redirect
#                  Use this when CloudFront sits in front of the ALB
#                  and sends requests over HTTP to the origin
# ================================================================

variable "listener_mode" {
  description = "ALB listener mode: http_only | https_only | http_to_https | dual"
  type        = string
  default     = "http_only"

  validation {
    condition     = contains(["http_only", "https_only", "http_to_https", "dual"], var.listener_mode)
    error_message = "listener_mode must be one of: http_only, https_only, http_to_https, dual"
  }
}

variable "certificate_arn" {
  description = "ACM certificate ARN — required when listener_mode is https_only, http_to_https, or dual"
  type        = string
  default     = null
}

variable "default_service" {
  description = "Service key that receives all unmatched (root) traffic from the ALB default action"
  type        = string
}

# ================================================================
#  WAF
# ================================================================

variable "enable_waf" {
  description = "Whether to associate a WAF Web ACL with the ALB"
  type        = bool
  default     = false
}

variable "waf_web_acl_id" {
  description = "WAF Web ACL ARN to associate with the ALB (required when enable_waf = true)"
  type        = string
  default     = null
}

# ================================================================
#  SERVICES
# ================================================================

variable "services" {
  description = "Map of ECS services to deploy. Each key becomes the service/container name."
  type = map(object({
    # Container image
    image = string

    # Port the container listens on
    port = number

    # Fargate task sizing
    cpu    = string
    memory = string

    # Number of tasks to run
    desired_count = number

    # ALB routing
    path     = string           # path pattern, e.g. "/api/*"
    priority = number           # listener rule priority (lower = evaluated first)
    host     = optional(string) # optional host header for host-based routing

    # ALB health check
    health_check_path     = string
    health_check_protocol = optional(string, "HTTP")
    health_check_matcher  = optional(string, "200")

    # Environment variables (plain text)
    env = optional(map(string), {})

    # Secrets Manager injections
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })), [])

    # Private registry credentials (DockerHub etc.)
    repository_credentials = optional(string)

    # Autoscaling
    enable_autoscaling = optional(bool, false)
    min_capacity       = optional(number, 1)
    max_capacity       = optional(number, 2)
    cpu_target         = optional(number, 60)
    memory_target      = optional(number, 70)
    request_target     = optional(number, null)
  }))
}

# ================================================================
#  SECRETS (IAM access)
# ================================================================

variable "secrets_arns" {
  description = "List of Secrets Manager ARNs the ECS execution role needs GetSecretValue access to"
  type        = list(string)
  default     = []
}

# ================================================================
#  LOGGING
# ================================================================

variable "enable_logs" {
  description = "Create CloudWatch log groups and enable container log shipping"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# ================================================================
#  DEPLOYMENT
# ================================================================

variable "health_check_grace_period" {
  description = "Seconds ECS waits before starting ALB health checks on new tasks"
  type        = number
  default     = 60
}

variable "enable_exec" {
  description = "Enable ECS Exec (aws ecs execute-command) for live container debugging"
  type        = bool
  default     = false
}

variable "deployment_min_healthy" {
  description = "Minimum healthy task percentage during rolling deployment"
  type        = number
  default     = 50
}

variable "deployment_max_percent" {
  description = "Maximum task percentage allowed during rolling deployment"
  type        = number
  default     = 200
}

variable "enable_blue_green" {
  description = "Enable Blue/Green deployments via AWS CodeDeploy"
  type        = bool
  default     = false
}
