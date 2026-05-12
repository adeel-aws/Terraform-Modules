variable "project_name" { type = string }
variable "environment"  { type = string }
variable "region"       { type = string }

variable "default_service" {
  type = string
}

variable "services" {
  type = map(object({
    image             = string
    port              = number
    cpu               = string
    memory            = string
    desired_count     = number
    path              = string
    priority          = number
    health_check_path = string

    env     = optional(map(string), {})
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })), [])

    repository_credentials = optional(string)

    enable_autoscaling = optional(bool, false)
    min_capacity       = optional(number, 1)
    max_capacity       = optional(number, 2)

    cpu_target     = optional(number, 60)
    memory_target  = optional(number, 70)
    request_target = optional(number, 200)
  }))
}

variable "secrets_arns" {
  description = "List of Secrets Manager ARNs ECS can access"
  type        = list(string)
  default     = []
}

variable "subnets"         { type = list(string) }
variable "security_groups" { type = list(string) }

variable "assign_public_ip" {
  type    = bool
  default = false
}

variable "enable_alb" {
  type    = bool
  default = true
}

variable "vpc_id" { type = string }

variable "alb_subnets" {
  type = list(string)
}

variable "alb_security_groups" {
  type = list(string)
}

variable "enable_https" {
  type    = bool
  default = false
}

variable "certificate_arn" {
  type    = string
  default = null
}

variable "enable_logs" {
  type    = bool
  default = true
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "health_check_grace_period" {
  type    = number
  default = 60
}

variable "enable_exec" {
  type    = bool
  default = true
}

variable "deployment_min_healthy" {
  type    = number
  default = 50
}

variable "deployment_max_percent" {
  type    = number
  default = 200
}