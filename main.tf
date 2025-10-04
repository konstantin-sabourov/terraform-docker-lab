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

# Create a Docker network
resource "docker_network" "app_network" {
  name = "terraform_network"
}

# Nginx web server
resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_container" "nginx" {
  name  = "terraform-nginx"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.app_network.name
  }
}

# create another docker_container, nginx2, but on port 8081
resource "docker_container" "nginx2" {
    name  = "terraform-nginx2"
    image = docker_image.nginx.image_id
    ports {
        internal = 80
        external = 8081
    }
    networks_advanced {
        name = docker_network.app_network.name
    }
}

# # Simple output to show what was created
# output "nginx_url" {
#   value = "http://localhost:8081"
# }