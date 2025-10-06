# outputs.tf

output "application_url" {
  value       = "http://localhost:${var.nginx_port}"
  description = "Application URL"
}

output "service_ips" {
  value = {
    database = module.database.ip_address
    cache    = module.cache.ip_address
    webapp   = module.webapp.ip_address
    webapp2  = module.webapp2.ip_address
    proxy    = module.proxy.ip_address
  }
  description = "IP addresses of all services"
}

output "database_url" {
  value     = "postgresql://${var.db_user}:${var.db_password}@localhost:5432/${var.db_name}"
  sensitive = true
}