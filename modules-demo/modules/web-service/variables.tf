# modules/web-service/variables.tf

variable "service_name" {
  description = "Name of the service container"
  type        = string
}

variable "image_name" {
  description = "Docker image to use"
  type        = string
}

variable "network_name" {
  description = "Docker network to attach to"
  type        = string
}

variable "network_aliases" {
  description = "Network aliases for service discovery"
  type        = list(string)
  default     = []
}

variable "ports" {
  description = "Port mappings"
  type = list(object({
    internal = number
    external = number
  }))
  default = []
}

# FIXME: could not set in modules/web-services/main.tf
variable "environment_vars" {
  description = "Environment variables"
  type        = list(string)
  default     = []
}

variable "volumes" {
  description = "Volume mounts"
  type = list(object({
    volume_name    = string
    container_path = string
    read_only      = optional(bool)
  }))
  default = []
}

variable "restart_policy" {
  description = "Container restart policy"
  type        = string
  default     = "unless-stopped"
}

variable "healthcheck" {
  description = "Container health check configuration"
  type = object({
    test     = list(string)
    interval = string
    timeout  = string
    retries  = number
  })
  default = null
}

variable "command" {
  description = "Container command override"
  type        = list(string)
  default     = null
}

variable "config_files" {
  description = "Configuration files to upload to container"
  type = list(object({
    content = string
    file    = string
  }))
  default = []
}