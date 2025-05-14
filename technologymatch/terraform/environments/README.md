# Open WebUI Terraform Environments

This directory contains Terraform configurations for deploying Open WebUI in different environments (development, staging, production).

## Directory Structure

- `dev/`: Development environment configuration
- `prod/`: Production environment configuration (with production-grade settings)

## Deployment Process

### Prerequisites

- AWS CLI configured with a profile named `Technologymatch`
- Terraform installed (version 1.0.0 or later)
- kubectl installed for interacting with Kubernetes clusters

### Deployment Steps

1. Initialize Terraform:
   ```bash
   cd dev # or prod
   terraform init
   ```

2. Apply the Terraform configuration:
   ```bash
   terraform apply
   ```

3. Configure kubectl to connect to your EKS cluster:
   ```bash
   aws eks update-kubeconfig --name openwebui-dev-cluster-new --region us-east-1 --profile Technologymatch
   ```

4. Run the credentials script to create Kubernetes secrets:
   ```bash
   chmod +x create-aws-credentials-secret.sh && ./create-aws-credentials-secret.sh
   ```

## AWS Credentials Secret

### Why is the `create-aws-credentials-secret.sh` Script Necessary?

The `create-aws-credentials-secret.sh` script is necessary because:

1. **S3 Integration**: Open WebUI needs AWS credentials to access the S3 bucket where it stores user data, configurations, and other persistent information.

2. **IAM Limitation**: While EKS pods can use IAM roles for service accounts (IRSA), this requires more complex setup and isn't supported by all applications. For simpler deployment, Open WebUI uses explicit AWS credentials.

3. **Security Separation**: Keeping AWS credentials management separate from the infrastructure provisioning provides better security isolation and makes it easier to rotate credentials without redeploying infrastructure.

4. **Kubernetes Secret Management**: Terraform can create Kubernetes resources, but managing in-cluster secrets is more reliably done with kubectl after the cluster is fully operational.

The script:
- Extracts AWS credentials from your local AWS profile
- Creates a Kubernetes secret containing these credentials
- Makes the credentials available to the Open WebUI pods at runtime

This step must be performed after Terraform has successfully deployed the infrastructure but before you attempt to use Open WebUI with S3 storage.

## Multiple AI Provider Configuration

Open WebUI is configured to support multiple AI providers:

1. **OpenAI**: Primary provider for most AI interactions
2. **Anthropic**: Secondary provider for specific use cases
3. **Gemini**: Additional provider for variety and fallback

The configuration for these providers is set in the `values.yaml` file in each environment directory.