# ---------------------------------------------------------
# PROJECT
# ---------------------------------------------------------
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

# ---------------------------------------------------------
# INSTANCE
# ---------------------------------------------------------
variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "instance_types" {
  type    = list(string)
  default = []
}

variable "key_name" {
  type    = string
  default = null
}

variable "user_data" {
  type    = string
  default = null
}

# ---------------------------------------------------------
# SSM
# ---------------------------------------------------------
variable "enable_ssm" {
  type    = bool
  default = false
}

# ---------------------------------------------------------
# NETWORK
# ---------------------------------------------------------
variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

# ---------------------------------------------------------
# ROOT VOLUME
# ---------------------------------------------------------
variable "root_volume" {
  type = object({
    size      = number
    type      = string
    encrypted = bool
  })

  default = {
    size      = 20
    type      = "gp3"
    encrypted = true
  }
}

# ---------------------------------------------------------
# ADDITIONAL EBS VOLUMES
# ---------------------------------------------------------
variable "additional_ebs_volumes" {
  type = list(object({
    device_name = string    # ← caller must specify for extra volumes
    size        = number
    type        = string
    encrypted   = bool
  }))

  default = []
}

# ---------------------------------------------------------
# SCALING
# ---------------------------------------------------------
variable "scaling" {
  type = object({
    min     = number
    max     = number
    desired = number
  })

  validation {
    condition     = var.scaling.desired >= var.scaling.min && var.scaling.desired <= var.scaling.max
    error_message = "desired capacity must be between min and max."
  }
}

# ---------------------------------------------------------
# HEALTH CHECK
# ---------------------------------------------------------
variable "health_check_type" {
  type    = string
  default = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be EC2 or ELB."
  }
}

variable "health_check_grace_period" {
  type    = number
  default = 300
}

# ---------------------------------------------------------
# TARGET GROUPS
# ---------------------------------------------------------
variable "target_group_arns" {
  type    = list(string)
  default = []
}

# ---------------------------------------------------------
# INSTANCE REFRESH
# ---------------------------------------------------------
variable "enable_instance_refresh" {
  type    = bool
  default = true
}

variable "instance_refresh_min_healthy_percentage" {
  type    = number
  default = 50
}

# ---------------------------------------------------------
# MONITORING
# ---------------------------------------------------------
variable "enable_detailed_monitoring" {
  type    = bool
  default = true
}

# ---------------------------------------------------------
# TERMINATION
# ---------------------------------------------------------
variable "termination_policies" {
  type    = list(string)
  default = ["OldestInstance"]
}

variable "force_delete" {
  type    = bool
  default = true
}

variable "protect_from_scale_in" {
  type    = bool
  default = false
}

# ---------------------------------------------------------
# CPU AUTO SCALING
# ---------------------------------------------------------
variable "enable_cpu_scaling" {
  type    = bool
  default = false
}

variable "cpu_target_value" {
  type    = number
  default = 60
}

# ---------------------------------------------------------
# MEMORY AUTO SCALING
# ---------------------------------------------------------
variable "enable_memory_scaling" {
  type    = bool
  default = false
}

variable "memory_target_value" {
  type    = number
  default = 70
}

variable "memory_metric_name" {
  type    = string
  default = "mem_used_percent"
}

variable "memory_metric_namespace" {
  type    = string
  default = "CWAgent"
}

# ---------------------------------------------------------
# MIXED INSTANCES / SPOT
# ---------------------------------------------------------
variable "enable_mixed_instances_policy" {
  type    = bool
  default = false
}

variable "on_demand_base_capacity" {
  type    = number
  default = 0
}

variable "on_demand_percentage_above_base_capacity" {
  type    = number
  default = 100
}

variable "spot_allocation_strategy" {
  type    = string
  default = "capacity-optimized"
}

variable "capacity_rebalance" {
  type    = bool
  default = true
}

# ---------------------------------------------------------
# SCHEDULED SCALING
# ---------------------------------------------------------
variable "enable_scheduled_scaling" {
  type    = bool
  default = false
}

variable "scheduled_scaling" {
  type = object({
    scale_up_cron      = string
    scale_down_cron    = string
    scale_up_min       = number
    scale_up_max       = number
    scale_up_desired   = number
    scale_down_min     = number
    scale_down_max     = number
    scale_down_desired = number
  })

  default = null
}

# ---------------------------------------------------------
# TAGS
# ---------------------------------------------------------
variable "tags" {
  type    = map(string)
  default = {}
}