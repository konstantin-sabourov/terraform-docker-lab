# terraform-docker-lab

Sandbox on LAN

## Overview

This repository contains a Terraform configuration to set up
a multi-container application environment using Docker. The setup
includes:

- PostgreSQL database
- Redis in-memory data store
- Web application container
- Nginx reverse proxy for load balancing and serving

## Issues

1. No persistent database (Solved)

    ```bash
    # Create some data
    docker exec -it postgres_db psql -U appuser -d appdb -c "CREATE TABLE test (id INT, name TEXT);"
    docker exec -it postgres_db psql -U appuser -d appdb -c "INSERT INTO test VALUES (1, 'hello');"

    # Destroy and recreate
    terraform destroy
    terraform apply

    # Data persists!
    docker exec -it postgres_db psql -U appuser -d appdb -c "SELECT * FROM test;"
    ```

    ~~No, data does not persist. Try to bind a volume, or use docker-managed volumes, but avoid volume reset
    on `terraform destroy`~~

    **Solution**: Use an external Docker volume, `postgres_data`

2. Full reset

On `terraform destroy` the images are removed. External volumes by default are not removed.
