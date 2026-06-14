variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "enable_rate_limit" {
  type    = bool
  default = true
}

variable "rate_limit" {
  type    = number
  default = 2000
}

variable "tags" {
  type    = map(string)
  default = {}
}