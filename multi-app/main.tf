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

# Network for all services
resource "docker_network" "app_network" {
  name = "app_network"
}

# PostgreSQL Database
resource "docker_image" "postgres" {
  name = "postgres:15-alpine"
}

resource "docker_volume" "postgres_data" {
  name = "postgres_data"
}

resource "docker_container" "postgres" {
  name  = "postgres_db"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_USER=appuser",
    "POSTGRES_PASSWORD=apppassword",
    "POSTGRES_DB=appdb"
  ]

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name = docker_network.app_network.name
    aliases = ["database"]
  }

  healthcheck {
    # Have to provide db name.
    test     = ["CMD-SHELL", "pg_isready -U appuser -d appdb -p 5432"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# Redis Cache
resource "docker_image" "redis" {
  name = "redis:7-alpine"
}

resource "docker_container" "redis" {
  name  = "redis_cache"
  image = docker_image.redis.image_id

  networks_advanced {
    name = docker_network.app_network.name
    aliases = ["cache"]
  }

  healthcheck {
    test     = ["CMD", "redis-cli", "ping"]
    interval = "10s"
    timeout  = "3s"
    retries  = 5
  }
}

# Python Web Application (using a simple demo app)
resource "docker_image" "webapp" {
  name = "python:3.11-slim"
}

resource "docker_container" "webapp" {
  name  = "webapp"
  image = docker_image.webapp.image_id
  
  # Keep container running for demo
  command = ["tail", "-f", "/dev/null"]

  env = [
    "DATABASE_URL=postgresql://appuser:apppassword@database:5432/appdb",
    "REDIS_URL=redis://cache:6379",
    "APP_ENV=production"
  ]

  networks_advanced {
    name = docker_network.app_network.name
    aliases = ["webapp"]
  }

  # This container depends on database being healthy
  depends_on = [
    docker_container.postgres,
    docker_container.redis
  ]
}

# Nginx Reverse Proxy
resource "docker_image" "nginx" {
  name = "nginx:alpine"
}

resource "docker_container" "nginx" {
  name  = "nginx_proxy"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.nginx_port
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  upload {
    content = templatefile("${path.module}/nginx.conf.tpl", {
      backend_host = "webapp"
      backend_port = 8000
    })
    file = "/etc/nginx/nginx.conf"
  }

  depends_on = [docker_container.webapp]
}