# Terraform + Docker IaC Learning Progress

## Student Profile
- **Background**: Mid-career engineer, Ph.D. in Physics, solid coding and science background
- **Goal**: Build solid foundation in Infrastructure as Code (IaC), specifically Terraform
- **Timeline**: ~10 hours/week until November 3, 2025
- **Environment**: Mac Studio M4 with 64GB RAM, using Docker locally

## Completed Work

### Week 1-2: Terraform Basics with Docker (COMPLETED ✓)

**Location**: `~/terraform-docker-lab/`

#### Skills Mastered:
1. **Terraform Workflow**
   - `terraform init` - Initialize providers
   - `terraform plan` - Preview changes
   - `terraform apply` - Execute infrastructure changes
   - `terraform destroy` - Tear down infrastructure
   - `terraform state` - Inspect state

2. **Basic Infrastructure**
   - Created first Terraform project with Docker provider
   - Deployed Nginx container with port mapping
   - Understood state management (terraform.tfstate)
   - Learned resource dependencies (implicit and explicit)

3. **Multi-Container Application**
   - Built 3-tier application: Proxy → Web App → Database + Cache
   - Services: Nginx, Python webapp, PostgreSQL, Redis
   - Implemented service discovery via Docker networks
   - Used environment variables for configuration
   - Implemented health checks
   - Used configuration templates (`templatefile()`)

**Key Learning**: Persistent storage with Docker volumes
- Learned difference between Terraform-managed vs external volumes
- Issue encountered: Terraform-managed volumes are destroyed with `terraform destroy`
- Solution: Create volumes externally, reference by name in Terraform
- Command: `docker volume create postgres_data`

### Week 3: Terraform Modules (COMPLETED ✓)

**Location**: `~/terraform-docker-lab/modules-demo/`

#### Project Structure:
```
modules-demo/
├── main.tf                     # Root configuration
├── variables.tf                # Input variables
├── outputs.tf                  # Outputs
├── terraform.tfvars            # Variable values
├── nginx.conf.tpl              # Nginx config template
├── test-infrastructure.sh      # Health check script
└── modules/
    └── web-service/            # Reusable module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

#### Skills Mastered:
1. **Module Creation**
   - Built reusable `web-service` module
   - Defined module inputs (variables) and outputs
   - Used `source = "./modules/web-service"` for local modules

2. **Advanced Terraform Features**
   - `dynamic` blocks for conditional resources
   - `for_each` loops
   - `lookup()` function for default values
   - Variable validation rules
   - Sensitive outputs
   - Module dependencies

3. **Real Infrastructure Deployed**
   - 5 containers using same module: postgres-db, redis-cache, webapp, webapp2, nginx-proxy
   - Shared Docker network for service discovery
   - Load balancing (2 webapp instances with same DNS alias)
   - External persistent PostgreSQL volume
   - Working reverse proxy with health endpoint

4. **Testing & Verification**
   - Created comprehensive test script
   - Learned DNS-based service discovery
   - Verified inter-service communication
   - Tested load balancing

#### Important Lessons Learned:

**Issue 1: Environment Variables**
- **Problem**: Used `dynamic "env"` block, but `env` is not a block type
- **Solution**: `env = var.environment_vars` (simple list assignment)

**Issue 2: Persistent Volume**
- **Problem**: Data lost on `terraform destroy` even with `docker_volume` resource
- **Solution**: Create volume externally, reference by name string (not resource)

**Issue 3: Missing Tools in Containers**
- **Problem**: Python slim image lacks `ping`, `nc` for testing
- **Solution**: Use `getent hosts` for DNS checks, install tools when needed

**Issue 4: Stale Database Password**
- **Problem**: External volume kept old password from previous run
- **Solution**: Remove and recreate volume when changing credentials

**Issue 5: Webapp Not Listening**
- **Problem**: Container running `tail -f /dev/null` - no web server
- **Solution**: Changed command to `python3 -m http.server 8000`

## Current State

### Working Infrastructure:
```
Mac :8080 → [nginx-proxy] → [webapp, webapp2] → [postgres-db, redis-cache]
                                                      ↓
                                              [postgres_data volume]
```

All services verified working:
- ✓ All containers running and healthy
- ✓ DNS resolution working
- ✓ Inter-service communication working
- ✓ Database queries working
- ✓ Redis cache responding
- ✓ Load balancing across 2 webapp instances
- ✓ Nginx proxy responding on port 8080
- ✓ Data persistence across terraform destroy/apply

### Key Files to Reference:

**modules-demo/main.tf**: Root infrastructure using modules
**modules-demo/modules/web-service/**: Reusable module
**modules-demo/test-infrastructure.sh**: Comprehensive health checks

## Next Steps (Week 4)

### Planned: Remote State Management & Workspaces

**Topics to Cover:**
1. **Remote State Backends**
   - Why remote state matters (team collaboration)
   - Simulating remote backend locally
   - State locking mechanisms
   - Backend configuration

2. **Workspaces**
   - Creating dev/staging/prod environments
   - Workspace-specific configurations
   - Managing multiple environments with same code
   - Best practices for environment separation

3. **State Management**
   - State file structure and security
   - Sensitive data in state
   - State file recovery
   - terraform state commands (mv, rm, import)

4. **Team Workflows**
   - Collaboration patterns
   - State locking to prevent conflicts
   - Code review for infrastructure changes
   - CI/CD integration concepts

**Estimated Time**: 10 hours (Week 4)

## Future Topics (Beyond Week 4)

### Option A: Continue DevOps Path
- **CI/CD Integration**: GitHub Actions + Terraform
- **Secrets Management**: Handling sensitive data
- **Testing**: Terratest or similar frameworks
- **Production Patterns**: Blue-green deployments, canary releases

### Option B: Move to Kubernetes
- Kubernetes fundamentals
- Helm charts
- Terraform + Kubernetes provider
- GitOps with ArgoCD/Flux

### Option C: Real Cloud Providers
- Migrate current setup to AWS/GCP/Azure
- Cloud-specific IaC patterns
- Managed services (RDS, Cloud SQL, etc.)
- Multi-cloud considerations

## Resources Used

### Official Documentation:
- Terraform: https://developer.hashicorp.com/terraform/docs
- Docker Provider: https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs

### Recommended Reading:
- "Terraform: Up & Running" by Yevgeniy Brikman
- HashiCorp Learn tutorials: https://learn.hashicorp.com/terraform

## Commands Quick Reference

```bash
# Terraform workflow
terraform init          # Initialize project
terraform plan          # Preview changes
terraform apply         # Apply changes
terraform destroy       # Destroy infrastructure
terraform state list    # List resources
terraform output        # Show outputs

# Docker management
docker ps               # List containers
docker logs [name]      # View logs
docker exec [name] cmd  # Execute command
docker volume ls        # List volumes
docker network inspect  # Inspect network

# Testing
./test-infrastructure.sh  # Run health checks
```

## Notes for Next Session

1. Current working directory: `~/terraform-docker-lab/modules-demo/`
2. External volume `postgres_data` must exist before applying
3. All services use `app_network` Docker network
4. Password in `terraform.tfvars`: `db_password = "secure_password_123"`
5. Access app at: http://localhost:8080/
6. Health check at: http://localhost:8080/health

## Questions to Explore Next Session

- How to handle secrets in team environments?
- How to manage infrastructure across multiple environments?
- How to integrate Terraform with version control and CI/CD?
- When to use modules vs. separate Terraform projects?

---

**Last Updated**: October 6, 2025  
**Status**: Week 3 Complete, Ready for Week 4
