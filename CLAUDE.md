# Claude Instructions for Open WebUI Deployment

This file contains instructions for Claude on deploying Open WebUI infrastructure.

## Commands That Claude Can Run

Claude can run these commands to help set up and verify the deployment:

```bash
# Initialize Terraform
cd /root/dev/forks/technologymatch/open-webui-helm-charts/technologymatch/terraform/environments/dev
terraform init

# Verify the plan (preview resources to be created)
terraform plan

# Configure kubectl after deployment
aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name) --region us-east-1 --profile Technologymatch

# Verify EKS deployment
kubectl get nodes
kubectl get pods -n open-webui-dev

# Check Load Balancer
kubectl get svc -n open-webui-dev

# Wait for deployment to complete
kubectl rollout status deployment/open-webui -n open-webui-dev

# Verify database connection
kubectl logs deploy/open-webui -n open-webui-dev | grep -i database

# Check application logs
kubectl logs -n open-webui-dev deploy/open-webui

# Setup monitoring
kubectl top nodes
kubectl top pods -n open-webui-dev
```

## Commands For User to Run

Claude should NOT run these commands due to execution time limits. Instead, Claude should prompt the user to run these:

```bash
# Deploy Infrastructure (will take more than 2 minutes)
terraform apply

# For production deployment
cd /root/dev/forks/technologymatch/open-webui-helm-charts/technologymatch/terraform/environments/prod
terraform init
terraform plan
terraform apply
```

## Troubleshooting Commands

Claude can run these troubleshooting commands:

```bash
# Check pod details for issues
kubectl describe pod -n open-webui-dev

# Check specific container logs
kubectl logs -n open-webui-dev deploy/open-webui -c open-webui

# Check EKS cluster status
aws eks describe-cluster --name openwebui-dev-cluster --profile Technologymatch

# Check security groups
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=open-webui" --profile Technologymatch

# Check S3 bucket
aws s3 ls s3://technologymatch-open-webui-dev --profile Technologymatch
```

## Verification Checklist

After deployment, Claude should help verify:

1. EKS cluster is running and nodes are healthy
2. Pods are in Running state
3. Load balancer has a public endpoint
4. Database connection is successful
5. S3 bucket is properly configured
6. The web UI is accessible at the load balancer endpoint or domain

## Common Issues & Solutions

Claude should suggest these solutions for common problems:

1. **Pods stuck in Pending**: Check node capacity and resource requests
2. **Database connection failed**: Verify security groups and credentials
3. **S3 access issues**: Check IAM roles and permissions
4. **Load balancer not provisioning**: Check AWS service quotas and VPC configuration
5. **Application startup errors**: Check application logs for configuration issues

Remember: The `terraform apply` command should be run by the user directly, as it exceeds Claude's 2-minute execution time limit.