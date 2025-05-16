#!/bin/bash
# Script to monitor the health of the Open WebUI deployment

set -e

# Get the namespace from terraform outputs
if terraform output -json >/dev/null 2>&1; then
  # Try to get namespace from terraform output
  NAMESPACE=$(terraform output -raw namespace 2>/dev/null || echo "")
  
  # If not found in terraform output, try to extract from main.tf
  if [ -z "$NAMESPACE" ]; then
    NAMESPACE=$(grep -A 2 'unique_suffix = ' main.tf | grep -oP '(?<="v).*(?=")' | awk '{print "open-webui-dev-v" $1}')
  fi
else
  # If terraform output fails, fall back to main.tf parsing
  NAMESPACE=$(grep -A 2 'unique_suffix = ' main.tf | grep -oP '(?<="v).*(?=")' | awk '{print "open-webui-dev-v" $1}')
fi

# Default fallback
if [ -z "$NAMESPACE" ]; then
  echo "⚠️ Could not determine namespace, using default"
  NAMESPACE="open-webui-dev-v6"
fi

echo "🔍 Monitoring deployment in namespace: $NAMESPACE"

# Get cluster info
echo "🌐 Checking EKS cluster status..."
aws eks describe-cluster --name $(terraform output -raw eks_cluster_name) --region us-east-1 --profile Technologymatch | jq -r '.cluster.status'

# Configure kubectl to use the right context
echo "⚙️ Configuring kubectl..."
aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name) --region us-east-1 --profile Technologymatch

# Check node status
echo "🖥️ Checking EKS nodes..."
kubectl get nodes

# Check pod status
echo "📦 Checking Open WebUI pods..."
kubectl get pods -n $NAMESPACE

# Check service status
echo "🔌 Checking Open WebUI services..."
kubectl get svc -n $NAMESPACE

# Check load balancer status
echo "⚖️ Checking load balancer..."
LB_HOSTNAME=$(kubectl get svc -n $NAMESPACE open-webui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Load balancer hostname: $LB_HOSTNAME"

# Check DNS resolution
echo "🌍 Checking DNS resolution..."
nslookup ai-dev.technologymatch.com

# Check service logs
echo "📝 Checking application logs (last 20 lines)..."
kubectl logs -n $NAMESPACE deploy/open-webui --tail=20

# Check if the site is accessible
echo "🌐 Checking if site is accessible..."
if curl -s -m 10 -o /dev/null -w "%{http_code}" https://ai-dev.technologymatch.com/health; then
  echo "✅ Site health endpoint is accessible!"
else
  echo "❌ Site health endpoint is not accessible"
fi

echo "👨‍💻 Deployment monitoring complete!"