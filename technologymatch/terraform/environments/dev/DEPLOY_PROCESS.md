# Open WebUI Deployment Process

This document outlines the current process for deploying the Open WebUI stack in a development environment. It includes both the automated Terraform deployment and the manual steps currently required to get HTTPS working properly.

## Architecture Overview

The deployment creates:

- VPC with public, private, and database subnets
- RDS PostgreSQL database
- S3 bucket for persistent storage
- EKS cluster
- AWS Load Balancer Controller
- Open WebUI Helm deployment
- ACM certificate for TLS
- Route53 DNS configuration

## Prerequisites

- AWS CLI configured with `Technologymatch` profile
- Terraform v1.0.0+ installed
- kubectl installed
- helm v3+ installed
- Access to AWS Route53 hosted zone for `technologymatch.com`

## Deployment Process

### 1. Initial Terraform Deployment

The primary deployment is handled by Terraform:

```bash
# Initialize Terraform
cd /root/dev/forks/technologymatch/open-webui-helm-charts/technologymatch/terraform/environments/dev-new
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure (takes ~20-30 minutes)
terraform apply
```

### 2. Manual Step: Update DNS for HTTPS Support

> **IMPORTANT**: This step is required for HTTPS to work properly and requires manual intervention.

The current issue is that Terraform creates a CNAME record pointing to the Service LoadBalancer, but HTTPS termination happens at the ALB created by the Ingress controller. You need to manually update the DNS record:

1. Get the Ingress ALB hostname:
   ```bash
   kubectl get ingress open-webui -n open-webui-dev-v6 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```

2. Update the Route53 DNS record (replace the ALB hostname with the one from your deployment):
   ```bash
   aws route53 change-resource-record-sets --hosted-zone-id Z07129941DJZPRC9P0HJW --change-batch '{
     "Changes": [
       {
         "Action": "UPSERT",
         "ResourceRecordSet": {
           "Name": "ai-dev.technologymatch.com",
           "Type": "CNAME",
           "TTL": 300,
           "ResourceRecords": [
             {
               "Value": "k8s-openwebui-XXXXXXXXXX-XXXXXXXXXXXX.us-east-1.elb.amazonaws.com"
             }
           ]
         }
       }
     ]
   }' --profile Technologymatch
   ```

### 3. Verify the Deployment

Wait 5-10 minutes for DNS to propagate, then:

1. Verify the database connection:
   ```bash
   kubectl logs deploy/open-webui -n open-webui-dev-v6 | grep -i database
   ```

2. Verify the load balancer and ingress:
   ```bash
   kubectl get svc,ingress -n open-webui-dev-v6
   ```

3. Access the application:
   - HTTP: http://ai-dev.technologymatch.com
   - HTTPS: https://ai-dev.technologymatch.com (should redirect HTTP to HTTPS)

## Known Issues

### 1. Manual DNS Update Required

**Issue**: The Terraform configuration creates a DNS record pointing to the Kubernetes Service's LoadBalancer, but the HTTPS termination happens at the Ingress ALB.

**Current Workaround**: Manually update the DNS record to point to the Ingress ALB after deployment.

**Future Solution**: Modify the Terraform configuration to automatically identify and use the Ingress ALB for DNS configuration.

### 2. Ingress ALB Not Properly Tracked in Terraform

**Issue**: The Ingress ALB is created by the AWS Load Balancer Controller which is deployed through Helm, making it difficult to reference directly in Terraform.

**Current Workaround**: Manually identify the ALB endpoint.

**Future Solution**: Use AWS data sources to identify the ALB created by the Ingress and incorporate it into the Terraform state.

## Future Improvements

1. **Automatic DNS Configuration**: Create a data source to find the Ingress ALB and use it for the Route53 record.

2. **Custom Resource Definition**: Potentially use a CRD or custom provider to bridge the gap between Kubernetes Ingress and Terraform state.

3. **Simplified Architecture**: Consider streamlining the architecture to use a single load balancer with TLS termination.

4. **Health Check Improvements**: Add more robust health checks and monitoring for the deployment.

## Complete Reset and Redeploy

If you need to completely reset and redeploy:

1. Destroy the existing infrastructure:
   ```bash
   terraform destroy
   ```

2. Update the version number in `main.tf` (under `locals` block):
   ```hcl
   unique_suffix = "v7"  # Increment this number
   ```

3. Update the version in `create-aws-credentials-secret.sh`:
   ```bash
   unique_suffix="v7"  # Increment this number to match
   ```

4. Deploy again following the steps above.

## Troubleshooting

### Unable to access HTTPS

1. Verify the DNS record points to the Ingress ALB:
   ```bash
   nslookup ai-dev.technologymatch.com
   ```

2. Check the Ingress configuration:
   ```bash
   kubectl describe ingress open-webui -n open-webui-dev-v6
   ```

3. Verify ACM certificate is properly attached:
   ```bash
   aws acm describe-certificate --certificate-arn $(terraform output -raw db_secret_arn | sed 's/db-credentials/acm-certificate/') --profile Technologymatch
   ```

### Pods failing to start

1. Check pod logs:
   ```bash
   kubectl logs -n open-webui-dev-v6 deploy/open-webui
   ```

2. Check pod events:
   ```bash
   kubectl describe pod -n open-webui-dev-v6 -l app.kubernetes.io/component=open-webui
   ```