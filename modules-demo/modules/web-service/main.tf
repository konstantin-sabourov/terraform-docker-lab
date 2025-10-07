# modules/web-service/main.tf

# terraform docker provider added. Must be in module?
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_image" "service" {
  name         = var.image_name
  keep_locally = true
}

resource "docker_container" "service" {
  name  = var.service_name
  image = docker_image.service.image_id

  dynamic "ports" {
    for_each = var.ports
    content {
      internal = ports.value.internal
      external = ports.value.external
    }
  }

  env = var.environment_vars

  networks_advanced {
    name    = var.network_name
    aliases = var.network_aliases
  }

  dynamic "volumes" {
    for_each = var.volumes
    content {
      volume_name    = volumes.value.volume_name
      container_path = volumes.value.container_path
      read_only      = lookup(volumes.value, "read_only", false)
    }
  }

  restart = var.restart_policy

  dynamic "healthcheck" {
    for_each = var.healthcheck != null ? [var.healthcheck] : []
    content {
      test     = healthcheck.value.test
      interval = healthcheck.value.interval
      timeout  = healthcheck.value.timeout
      retries  = healthcheck.value.retries
    }
  }

  command = var.command

  dynamic "upload" {
    for_each = var.config_files
    content {
      content = upload.value.content
      file    = upload.value.file
    }
  }
}