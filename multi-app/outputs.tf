output "application_url" {
  value       = "http://localhost:${var.nginx_port}"
  description = "URL to access the application"
}

output "database_connection" {
  value       = "postgresql://appuser:apppassword@localhost:5432/appdb"
  description = "Database connection string (for debugging)"
  sensitive   = true
}

output "container_ips" {
  value = {
    postgres = docker_container.postgres.network_data[0].ip_address
    redis    = docker_container.redis.network_data[0].ip_address
    webapp   = docker_container.webapp.network_data[0].ip_address
    nginx    = docker_container.nginx.network_data[0].ip_address
  }
  description = "Internal IP addresses of containers"
}