variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "name" {
  type = string
}

# ---------------------------------------------------------
# LOAD BALANCER
# ---------------------------------------------------------
variable "lb_type" {

  type    = string
  default = "application"

  validation {
    condition = contains(
      ["application", "network"],
      var.lb_type
    )

    error_message = "lb_type must be application or network."
  }
}

variable "internal" {
  type    = bool
  default = false
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "enable_deletion_protection" {
  type    = bool
  default = false
}

variable "enable_cross_zone_load_balancing" {
  type    = bool
  default = true
}

# ---------------------------------------------------------
# ALB ADVANCED SETTINGS
# ---------------------------------------------------------
variable "idle_timeout" {
  type    = number
  default = 60
}

variable "drop_invalid_header_fields" {
  type    = bool
  default = true
}

# ---------------------------------------------------------
# ACCESS LOGS
# ---------------------------------------------------------
variable "enable_access_logs" {
  type    = bool
  default = false
}

variable "access_logs_bucket" {
  type    = string
  default = null
}

variable "access_logs_prefix" {
  type    = string
  default = null
}

# ---------------------------------------------------------
# WAF
# ---------------------------------------------------------
variable "enable_waf" {
  type    = bool
  default = false
}

variable "waf_acl_arn" {
  type    = string
  default = null
}

# ---------------------------------------------------------
# HTTP LISTENER
# ---------------------------------------------------------
variable "enable_http_listener" {
  type    = bool
  default = true
}

variable "http_listener_port" {
  type    = number
  default = 80
}

# ---------------------------------------------------------
# HTTPS LISTENER
# ---------------------------------------------------------
variable "enable_https_listener" {
  type    = bool
  default = false
}

variable "https_listener_port" {
  type    = number
  default = 443
}

variable "certificate_arn" {

  type    = string
  default = null

  validation {
    condition = (
      !var.enable_https_listener ||
      var.certificate_arn != null
    )

    error_message = "certificate_arn required for HTTPS listener."
  }
}

variable "ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-2016-08"
}

# ---------------------------------------------------------
# REDIRECT
# ---------------------------------------------------------
variable "enable_https_redirect" {
  type    = bool
  default = false
}

# ---------------------------------------------------------
# TARGET GROUPS
# ---------------------------------------------------------
variable "default_target_group" {
  type = string
}

variable "target_groups" {

  type = map(object({

    port     = number
    protocol = string

    target_type = optional(string, "instance")

    target_ids = optional(list(string), [])

    deregistration_delay = optional(number, 300)

    health_check_enabled  = optional(bool, true)
    health_check_path     = optional(string, "/")
    health_check_port     = optional(string, "traffic-port")
    health_check_protocol = optional(string)
    health_check_interval = optional(number, 30)
    health_check_timeout  = optional(number, 5)
    healthy_threshold     = optional(number, 2)
    unhealthy_threshold   = optional(number, 2)

    matcher = optional(string, "200-399")

    enable_stickiness = optional(bool, false)
    stickiness_type   = optional(string, "lb_cookie")

    slow_start = optional(number, 0)

    load_balancing_algorithm_type = optional(
      string,
      "round_robin"
    )

    proxy_protocol_v2 = optional(bool, false)

    paths = optional(list(string), [])

    host_headers = optional(list(string), [])

    priority = optional(number)
  }))
}

# ---------------------------------------------------------
# TLS LISTENERS (NLB) — supports multiple ports
# ---------------------------------------------------------
variable "tls_listeners" {
  description = "Map of TLS listeners for NLB. Each entry creates one listener. certificate_arn and ssl_policy are optional per listener — falls back to module-level certificate_arn and ssl_policy if not set."
  type = map(object({
    port            = number
    target_group    = optional(string)
    certificate_arn = optional(string)
    ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
  }))
  default = {}
}

# ---------------------------------------------------------
# TCP LISTENERS (NLB) — supports multiple ports
# ---------------------------------------------------------
variable "tcp_listeners" {
  description = "Map of TCP listeners for NLB. Each entry creates one listener on the given port."
  type = map(object({
    port         = number
    target_group = optional(string)
  }))
  default = {}
}

# ---------------------------------------------------------
# UDP LISTENERS (NLB) — supports multiple ports
# ---------------------------------------------------------
variable "udp_listeners" {
  description = "Map of UDP listeners for NLB. Each entry creates one listener on the given port."
  type = map(object({
    port         = number
    target_group = optional(string)
  }))
  default = {}
}

# ---------------------------------------------------------
# TCP_UDP LISTENERS (NLB) — supports multiple ports
# ---------------------------------------------------------
variable "tcp_udp_listeners" {
  description = "Map of TCP_UDP listeners for NLB. Each entry creates one listener on the given port."
  type = map(object({
    port         = number
    target_group = optional(string)
  }))
  default = {}
}

# ---------------------------------------------------------
# TAGS
# ---------------------------------------------------------
variable "tags" {
  type    = map(string)
  default = {}
}