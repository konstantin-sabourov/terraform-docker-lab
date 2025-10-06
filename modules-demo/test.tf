# test.tf

# Null resource to run tests after deployment
resource "null_resource" "health_check" {
  depends_on = [
    module.database,
    module.cache,
    module.webapp,
    module.webapp2,
    module.proxy
  ]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for services to be ready..."
      sleep 10
      
      echo "Testing database..."
      docker exec postgres-db psql -U ${var.db_user} -d ${var.db_name} -c "SELECT 'DB OK' as status;"
      
      echo "Testing Redis..."
      docker exec redis-cache redis-cli ping
      
      echo "Testing Nginx..."
      curl -f http://localhost:${var.nginx_port}/health || exit 1
      
      echo "All services are healthy!"
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}