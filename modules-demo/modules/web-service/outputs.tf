# modules/web-service/outputs.tf

output "container_id" {
  description = "ID of the created container"
  value       = docker_container.service.id
}

output "container_name" {
  description = "Name of the created container"
  value       = docker_container.service.name
}

output "ip_address" {
  description = "Internal IP address"
  value       = docker_container.service.network_data[0].ip_address
}

output "image_id" {
  description = "Image ID used"
  value       = docker_image.service.image_id
}