# Technologymatch Open WebUI Customizations

This directory contains Technologymatch-specific customizations and infrastructure code for deploying Open WebUI to AWS.

## Contents

- `/terraform`: Infrastructure as Code (IaC) for AWS deployment
  - `/modules`: Reusable Terraform modules for AWS components
  - `/environments`: Environment-specific configurations for dev and prod
  
- `CUSTOM_CODE_DEPLOYMENT.md`: Guide for making custom changes to the Open WebUI application code
- `FORK_MANAGEMENT.md`: Documentation on managing upstream updates with our fork

## Overview

These customizations enable Technologymatch to deploy Open WebUI with:

1. **Secure AWS Infrastructure**:
   - VPC with private subnets
   - EKS cluster with proper IAM roles
   - RDS PostgreSQL database in private subnet
   - S3 bucket for storage with encryption
   - Route53 domain configuration at ai.technologymatch.com

2. **Environment Management**:
   - Development environment (smaller resources, spot instances)
   - Production environment (higher reliability, on-demand instances)
   - Separated configuration but consistent architecture

3. **Custom Image Support**:
   - Option to deploy custom Open WebUI container images
   - Integration with AWS ECR
   - Simple upgrade and rollback processes

## Quick Start

To deploy Open WebUI:

1. Choose your environment:
   ```
   cd terraform/environments/dev  # or prod
   ```

2. Initialize Terraform:
   ```
   terraform init
   ```

3. Apply the infrastructure:
   ```
   terraform apply
   ```

See the terraform directory README for full deployment instructions.

## Customization Files

This directory keeps all Technologymatch-specific files separate from the upstream repository structure, making it clear which parts are our customizations and which are from the original project. This separation helps with:

1. More easily incorporating upstream updates
2. Clear documentation of our specific changes
3. Maintaining organization-specific configurations

## Maintenance

When updating the Open WebUI Helm charts:

1. Pull the latest changes from upstream
2. Check for any changes that might affect our custom infrastructure
3. Test updates in the development environment first
4. Update our documentation if infrastructure changes are needed

For detailed procedures on managing updates, see the included documentation files.