# Open WebUI AWS Infrastructure

This repository contains Terraform code to deploy Open WebUI to AWS with a secure, production-ready infrastructure. The infrastructure includes:

- VPC with public, private, and database subnets
- RDS PostgreSQL database with encrypted storage
- S3 bucket for persistent storage
- EKS cluster for Kubernetes workloads
- Route53 domain configuration with SSL certificate
- Separate environments for development and production

## Prerequisites

- AWS CLI configured with the `Technologymatch` profile
- Terraform v1.0.0+ installed
- kubectl installed
- helm v3+ installed

## Infrastructure Overview

The infrastructure is organized as follows:

```
terraform/
├── modules/            # Reusable Terraform modules
│   ├── eks/            # Amazon EKS cluster configuration
│   ├── rds/            # Amazon RDS (PostgreSQL) configuration
│   ├── route53/        # Route53 and ACM certificate configuration
│   ├── s3/             # S3 bucket for storage
│   └── vpc/            # VPC network configuration
└── environments/       # Environment-specific configurations
    ├── dev/            # Development environment
    └── prod/           # Production environment
```

## Security Features

- **Private Database**: RDS is deployed in private subnets, accessible only from the EKS cluster
- **Encrypted Storage**: All database and S3 storage is encrypted at rest
- **IAM Roles**: Proper IAM roles and policies with least privilege
- **Security Groups**: Restricted access through security groups
- **TLS Certificates**: SSL certificates for HTTPS access
- **Network Isolation**: Proper network segmentation with public, private, and database subnets

## Deployment Instructions

### Development Environment

1. Navigate to the dev environment directory:
   ```
   cd terraform/environments/dev
   ```

2. Initialize Terraform:
   ```
   terraform init
   ```

3. Apply the infrastructure:
   ```
   terraform apply
   ```

4. Configure kubectl to connect to the EKS cluster:
   ```
   aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name) --region us-east-1 --profile Technologymatch
   ```

5. Check the deployed resources:
   ```
   kubectl get pods -n open-webui-dev
   ```

### Production Environment

1. Navigate to the prod environment directory:
   ```
   cd terraform/environments/prod
   ```

2. Initialize Terraform:
   ```
   terraform init
   ```

3. Apply the infrastructure:
   ```
   terraform apply
   ```

4. Configure kubectl to connect to the EKS cluster:
   ```
   aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name) --region us-east-1 --profile Technologymatch
   ```

5. Check the deployed resources:
   ```
   kubectl get pods -n open-webui-prod
   ```

## Accessing the Application

- **Development**: Access the application at `https://ai-dev.technologymatch.com`
- **Production**: Access the application at `https://ai.technologymatch.com`

## Managing OpenAI API Keys

For security reasons, you should store your OpenAI API keys in AWS Secrets Manager and use them in your deployment:

1. Create a secret for your API key:
   ```
   aws secretsmanager create-secret --name openai-api-key --secret-string "your-api-key" --profile Technologymatch
   ```

2. Update your Helm values to reference the secret:
   ```yaml
   extraEnvFrom:
     - secretRef:
         name: openai-api-key
   ```

## Backup and Disaster Recovery

- **Database Backups**: RDS is configured with automated backups (7 days for dev, 14 days for prod)
- **S3 Versioning**: S3 bucket has versioning enabled to prevent accidental deletion
- **Multi-AZ**: Production database is configured for multi-AZ deployment for high availability

## Scaling

- **Horizontal Pod Autoscaler**: Configure HPA for your Open WebUI deployment to scale based on CPU/memory usage
- **Node Autoscaling**: EKS node groups are configured to scale from min to max nodes based on demand

## Monitoring and Logging

For monitoring, you may want to add:

- Amazon CloudWatch for logging and monitoring
- Prometheus and Grafana for detailed Kubernetes monitoring
- AWS X-Ray for request tracing

## Cost Optimization

- Development environment uses SPOT instances to reduce costs
- Production uses on-demand instances for reliability
- Autoscaling helps adjust resources based on demand

## Security Best Practices

- Regularly update your Kubernetes and database versions
- Implement network policies to restrict pod-to-pod communication
- Use Secrets Manager for all credentials
- Enable EKS control plane logging
- Review IAM permissions regularly

## Troubleshooting

- **Database Connection Issues**: Verify security group rules and network ACLs
- **EKS Pod Failures**: Check pod logs with `kubectl logs -n open-webui-{env} {pod-name}`
- **Terraform Errors**: Run `terraform plan` to identify issues before applying

## Destroying the Infrastructure

To tear down the infrastructure:

```
terraform destroy
```

**Warning**: This will delete all resources including databases and persistent storage!