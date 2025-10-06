# variables.tf

variable "network_name" {
  description = "Name of the Docker network"
  type        = string
  default     = "app_network"
}

variable "nginx_port" {
  description = "External port for Nginx"
  type        = number
  default     = 8080
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "environment" {
  description = "Application environment"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}