variable "bucket_name" { 
  type = string 
  }
variable "force_destroy" {
   type = bool
    default = false 
    }
variable "tags" { 
  type = map(string) 
  default = {} 
  }

variable "enable_versioning" { 
  type = bool
   default = false 
   }

variable "allow_public_access" { 
  type = bool
   default = false 
   }

# Block Public Access
variable "block_public_acls" { 
  type = bool 
  default = true 
  }
variable "block_public_policy" { 
  type = bool
  default = true 
  }
variable "ignore_public_acls" { 
  type = bool 
  default = true 
  }
variable "restrict_public_buckets" { 
  type = bool
  default = true 
  }

# Static website
variable "enable_static_website" { 
  type = bool 
  default = false 
  }
variable "index_document" { 
  type = string 
  default = "index.html" 
  }
variable "error_document" { 
  type = string 
  default = "error.html" 
  }

# Bucket policy
variable "attach_policy" { 
  type = bool 
  default = false 
  }
variable "bucket_policy" { 
  type = string 
  default = "" 
  }

# Lifecycle
variable "enable_lifecycle_rule" { 
  type = bool 
  default = false 
  }
variable "lifecycle_expiration_days" { 
  type = number 
  default = 30 
  }
variable "lifecycle_transition_days" { 
  type = number 
  default = 0 
  }
variable "lifecycle_storage_class" { 
  type = string 
  default = "STANDARD_IA" 
  }

# Logging
variable "enable_logging" { 
  type = bool 
  default = false 
  }
variable "log_bucket" { 
  type = string 
  default = "" 
  }
variable "log_prefix" { 
  type = string 
  default = "" 
  }
variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}