variable "nginx_port" {
  description = "External port for Nginx reverse proxy"
  type        = number
  default     = 8080
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
}