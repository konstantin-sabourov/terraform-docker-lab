# main.tf

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Shared network
resource "docker_network" "app_network" {
  name = var.network_name
}

# Database service using our module
module "database" {
  source = "./modules/web-service"

  service_name    = "postgres-db"
  image_name      = "postgres:15-alpine"
  network_name    = docker_network.app_network.name
  network_aliases = ["database", "db"]

  environment_vars = [
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=${var.db_name}"
  ]

  volumes = [
    {
      volume_name    = "postgres_data"
      container_path = "/var/lib/postgresql/data"
    }
  ]

  healthcheck = {
    test     = ["CMD-SHELL", "pg_isready -U ${var.db_user}"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# Redis cache using our module
module "cache" {
  source = "./modules/web-service"

  service_name    = "redis-cache"
  image_name      = "redis:7-alpine"
  network_name    = docker_network.app_network.name
  network_aliases = ["cache", "redis"]

  healthcheck = {
    test     = ["CMD", "redis-cli", "ping"]
    interval = "10s"
    timeout  = "3s"
    retries  = 5
  }
}

# Nginx reverse proxy using our module
module "proxy" {
  source = "./modules/web-service"

  service_name = "nginx-proxy"
  image_name   = "nginx:alpine"
  network_name = docker_network.app_network.name

  ports = [
    {
      internal = 80
      external = var.nginx_port
    }
  ]

  config_files = [
    {
      content = templatefile("${path.module}/nginx.conf.tpl", {
        backend_host = "webapp"
        backend_port = 8000
      })
      file = "/etc/nginx/nginx.conf"
    }
  ]

  # Proxy depends on other services
  depends_on = [module.webapp]
}

# Web application using our module
module "webapp" {
  source = "./modules/web-service"

  service_name    = "webapp"
  image_name      = "python:3.11-slim"
  network_name    = docker_network.app_network.name
  network_aliases = ["webapp", "app"]

  command = ["tail", "-f", "/dev/null"]

  environment_vars = [
    "DATABASE_URL=postgresql://${var.db_user}:${var.db_password}@database:5432/${var.db_name}",
    "REDIS_URL=redis://cache:6379",
    "APP_ENV=${var.environment}"
  ]

  # Webapp depends on database and cache
  depends_on = [module.database, module.cache]
}

# Second webapp instance for load balancing
module "webapp2" {
  source = "./modules/web-service"

  service_name    = "webapp2"
  image_name      = "python:3.11-slim"
  network_name    = docker_network.app_network.name
  network_aliases = ["webapp", "app"]  # Same aliases for load balancing

  command = ["tail", "-f", "/dev/null"]

  environment_vars = [
    "DATABASE_URL=postgresql://${var.db_user}:${var.db_password}@database:5432/${var.db_name}",
    "REDIS_URL=redis://cache:6379",
    "APP_ENV=${var.environment}"
  ]

  depends_on = [module.database, module.cache]
}