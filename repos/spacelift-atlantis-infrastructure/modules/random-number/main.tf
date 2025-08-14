terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

variable "min" {
  description = "Minimum value for the random integer"
  type        = number
  default     = 1
}

variable "max" {
  description = "Maximum value for the random integer"
  type        = number
  default     = 100
}

resource "random_integer" "default" {
  min = var.min
  max = var.max
}

output "result" {
  description = "The randomly generated integer"
  value       = random_integer.default.result
}
