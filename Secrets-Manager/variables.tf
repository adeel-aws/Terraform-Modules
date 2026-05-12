variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "name" {
  description = "Secret name"
  type        = string
}

variable "description" {
  type    = string
  default = ""
}

variable "secret_map" {
  type = map(string)
}

variable "recovery_window_in_days" {
  type    = number
  default = 7
}