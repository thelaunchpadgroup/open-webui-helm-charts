# Updating and Rolling Back Open WebUI

This document explains how to update Open WebUI to newer versions and rollback changes if needed.

## Updating Open WebUI

Open WebUI is frequently updated. Here's how to deploy the latest version:

### 1. Check for New Versions

First, check if a new version is available:

```bash
helm repo update
helm search repo open-webui/open-webui
```

This will show you the latest available version of the chart.

### 2. Update the Terraform Configuration

Update the `open_webui_version` variable in your environment's `variables.tf` file:

```hcl
variable "open_webui_version" {
  description = "Version of the Open WebUI Helm chart"
  type        = string
  default     = "6.14.0"  # Update to the latest version
}
```

### 3. Preview the Changes

Run a Terraform plan to see what will change:

```bash
cd terraform/environments/dev  # or prod
terraform plan
```

### 4. Apply the Update

Apply the changes:

```bash
terraform apply
```

### 5. Monitor the Deployment

Watch the deployment progress:

```bash
kubectl get pods -n open-webui-dev -w  # or open-webui-prod
```

### 6. Alternative: Direct Helm Upgrade

If you prefer to bypass Terraform for quick updates, you can use Helm directly:

```bash
# Get current values
kubectl get configmap -n open-webui-dev open-webui-helm-values -o yaml > current-values.yaml

# Update the chart
helm upgrade open-webui open-webui/open-webui \
  --namespace open-webui-dev \
  --version 6.14.0 \  # New version
  -f current-values.yaml
```

Note: Using this direct method won't update your Terraform state. It's recommended to update via Terraform when possible.

## Rolling Back Changes

If you encounter issues after an update, you can roll back to a previous version:

### 1. Rolling Back via Terraform

If you used Terraform to update, you can roll back by changing the version number back:

```hcl
variable "open_webui_version" {
  description = "Version of the Open WebUI Helm chart"
  type        = string
  default     = "6.13.0"  # Revert to the previous working version
}
```

Then run:

```bash
terraform apply
```

### 2. Rolling Back via Helm

If you need to roll back quickly, you can use Helm's rollback feature:

```bash
# List Helm release history
helm history open-webui -n open-webui-dev

# Roll back to a specific revision (e.g., revision 2)
helm rollback open-webui 2 -n open-webui-dev
```

### 3. Checking the Status After Rollback

Verify the rollback was successful:

```bash
helm status open-webui -n open-webui-dev
kubectl get pods -n open-webui-dev
```

## Best Practices for Updates

1. **Test in Development First**: Always update your development environment first and verify functionality before updating production.

2. **Database Backups**: Before major updates, take a snapshot of your RDS database:
   ```bash
   aws rds create-db-snapshot \
     --db-instance-identifier openwebui-dev-postgres \
     --db-snapshot-identifier openwebui-pre-update-snapshot \
     --profile Technologymatch
   ```

3. **Keep Release Notes**: Document which versions are deployed and any issues encountered.

4. **Gradual Updates**: Avoid skipping multiple versions at once when possible.

## Troubleshooting Common Update Issues

### Pods Stuck in Terminating State

If pods are stuck during an update:

```bash
kubectl delete pod <pod-name> -n open-webui-dev --force --grace-period=0
```

### Database Migration Issues

If the new version has database schema changes:

1. Check the pod logs for migration errors:
   ```bash
   kubectl logs <pod-name> -n open-webui-dev
   ```

2. You may need to manually apply migrations or contact Open WebUI support.

### Container Image Pull Errors

If you see image pull errors:

```bash
kubectl describe pod <pod-name> -n open-webui-dev
```

This could indicate rate limiting or registry issues. Wait and retry, or check if the image version exists.

## Monitoring After Updates

After updating, monitor:

1. **Application Logs**:
   ```bash
   kubectl logs -l app=open-webui -n open-webui-dev
   ```

2. **Resource Usage**:
   ```bash
   kubectl top pods -n open-webui-dev
   ```

3. **Test Key Functionality**: Ensure all critical features work properly after the update.