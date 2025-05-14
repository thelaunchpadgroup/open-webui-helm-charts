# Open WebUI Terraform Configuration - Improved

This directory contains improved Terraform and Helm configuration for deploying Open WebUI on AWS EKS in a development environment.

## Key Improvements

1. **Reliable Load Balancer Creation**
   - Proper network load balancer configuration with internet-facing scheme
   - Explicit waits between resource creation for proper dependency management
   - Direct Kubernetes service integration for load balancer discovery
   - Proper DNS record configuration using A records with Alias target to the load balancer

2. **Better Resource Integration**
   - Removed hacky shell scripts for discovery and integration
   - Using native Terraform providers for direct resource access
   - Explicit namespace creation before Helm deployment
   - Improved dependency chain between resources

3. **Monitoring and Health Checks**
   - Enhanced health check configuration
   - Included monitoring script for deployment validation
   - Better logging configuration

## Deployment Instructions

### Prerequisites

- AWS CLI configured with the Technologymatch profile
- kubectl installed
- Terraform installed

### Steps to Deploy

1. Initialize Terraform:
   ```bash
   cd /root/dev/forks/technologymatch/open-webui-helm-charts/technologymatch/terraform/environments/dev-new
   terraform init
   ```

2. Review the plan:
   ```bash
   terraform plan
   ```

3. Deploy the infrastructure (NOTE: This will take ~20-30 minutes):
   ```bash
   terraform apply
   ```

4. Monitor the deployment:
   ```bash
   ./monitor-deployment.sh
   ```

5. Once deployed, the application will be available at:
   `https://ai-dev.technologymatch.com`

## Configuration Files

- **main.tf**: Main Terraform configuration with improved DNS and load balancer handling
- **values.yaml**: Helm values for Open WebUI with proper service configuration
- **terraform.tfvars**: Variables specific to this environment, including custom image configuration
- **monitor-deployment.sh**: Script to monitor and validate deployment health

## Notes

- The load balancer is explicitly configured as internet-facing in both the Kubernetes service and ingress
- DNS records are configured as A records with Alias targets to the load balancer
- Direct Kubernetes provider integration for service discovery
- Proper dependencies implemented with time_sleep resource for allowing AWS resources to fully provision
- Added lifecycle hooks for smoother resource updates

## Troubleshooting

If you encounter issues:

1. Check the pod status:
   ```bash
   kubectl get pods -n open-webui-dev-v5
   ```

2. Check the service and load balancer:
   ```bash
   kubectl get svc -n open-webui-dev-v5
   ```

3. Check the logs:
   ```bash
   kubectl logs -n open-webui-dev-v5 deploy/open-webui
   ```

4. Run the monitoring script:
   ```bash
   ./monitor-deployment.sh
   ```