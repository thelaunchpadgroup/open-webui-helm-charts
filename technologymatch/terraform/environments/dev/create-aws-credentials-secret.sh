#!/bin/bash
set -e

# Exit gracefully if jq is not available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq first."
    echo "On Ubuntu/Debian: sudo apt-get install -y jq"
    echo "On CentOS/RHEL: sudo yum install -y jq"
    echo "On macOS: brew install jq"
    exit 1
fi

# Configuration
unique_suffix="v6"
namespace="open-webui-dev-${unique_suffix}"
bucket="technologymatch-open-webui-dev-${unique_suffix}"
secret_name="openwebui-dev-${unique_suffix}/s3-credentials"
aws_profile="Technologymatch"
iam_user_name="openwebui-s3-user-dev-${unique_suffix}"
policy_name="openwebui-s3-policy-dev-${unique_suffix}"

# Check if S3 credentials already exist
echo "Checking if S3 credentials already exist in AWS Secrets Manager..."
if aws secretsmanager describe-secret --secret-id "$secret_name" --profile "$aws_profile" 2>/dev/null; then
  echo "Retrieving existing S3 credentials from AWS Secrets Manager..."
  CREDS_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "$secret_name" \
    --profile "$aws_profile" \
    --query SecretString \
    --output text)

  # Extract access key and secret key from JSON
  ACCESS_KEY=$(echo $CREDS_JSON | jq -r '.access_key')
  SECRET_KEY=$(echo $CREDS_JSON | jq -r '.secret_key')

  if [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ]; then
    echo "Error: Could not extract S3 credentials from AWS Secrets Manager"
    exit 1
  fi

  echo "Successfully retrieved existing S3 credentials."
else
  echo "S3 credentials not found in AWS Secrets Manager. Creating new credentials..."

  # First check if the IAM user already exists
  if aws iam get-user --user-name "$iam_user_name" --profile "$aws_profile" 2>/dev/null; then
    echo "IAM user $iam_user_name already exists. Will use existing user."
  else
    # Create a new IAM user for S3 access
    echo "Creating IAM user for S3 access..."
    aws iam create-user \
      --user-name "$iam_user_name" \
      --profile "$aws_profile" \
      --tags Key=Environment,Value=dev Key=Project,Value=open-webui Key=ManagedBy,Value=script
  fi

  # Create an IAM policy for specific S3 bucket access
  echo "Creating IAM policy for S3 access..."
  policy_document='{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "arn:aws:s3:::'$bucket'",
          "arn:aws:s3:::'$bucket'/*"
        ]
      }
    ]
  }'

  # Check if policy exists, create or update as needed
  if aws iam get-policy --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --profile "$aws_profile" --query Account --output text):policy/$policy_name" --profile "$aws_profile" 2>/dev/null; then
    echo "Policy $policy_name already exists. Deleting and recreating..."
    # Get all versions, delete non-default versions
    versions=$(aws iam list-policy-versions --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --profile "$aws_profile" --query Account --output text):policy/$policy_name" --profile "$aws_profile" --query 'Versions[?IsDefaultVersion==`false`].VersionId' --output text)
    for version in $versions; do
      aws iam delete-policy-version --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --profile "$aws_profile" --query Account --output text):policy/$policy_name" --version-id "$version" --profile "$aws_profile"
    done
    # Create new version
    aws iam create-policy-version --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --profile "$aws_profile" --query Account --output text):policy/$policy_name" --policy-document "$policy_document" --set-as-default --profile "$aws_profile"
  else
    # Create new policy
    aws iam create-policy \
      --policy-name "$policy_name" \
      --policy-document "$policy_document" \
      --profile "$aws_profile"
  fi

  # Attach the policy to the user
  echo "Attaching policy to IAM user..."
  aws iam attach-user-policy \
    --user-name "$iam_user_name" \
    --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --profile "$aws_profile" --query Account --output text):policy/$policy_name" \
    --profile "$aws_profile"

  # Create access key for the user
  echo "Creating access key for IAM user..."
  creds_output=$(aws iam create-access-key \
    --user-name "$iam_user_name" \
    --profile "$aws_profile")

  ACCESS_KEY=$(echo "$creds_output" | jq -r '.AccessKey.AccessKeyId')
  SECRET_KEY=$(echo "$creds_output" | jq -r '.AccessKey.SecretAccessKey')

  # Store credentials in AWS Secrets Manager
  echo "Storing S3 credentials in AWS Secrets Manager..."
  aws secretsmanager create-secret \
    --name "$secret_name" \
    --description "S3 credentials for Open WebUI dev environment" \
    --secret-string "{\"access_key\": \"$ACCESS_KEY\", \"secret_key\": \"$SECRET_KEY\", \"region\": \"us-east-1\"}" \
    --profile "$aws_profile" \
    --tags Key=Environment,Value=dev Key=Project,Value=open-webui Key=ManagedBy,Value=script

  echo "Successfully created and stored new S3 credentials."
fi

# Create credentials file content - using minimal permissions credentials
CREDENTIALS_CONTENT="[default]
aws_access_key_id = $ACCESS_KEY
aws_secret_access_key = $SECRET_KEY
region = us-east-1"

# Skip Kubernetes operations - they will be handled by Helm
echo "Skipping Kubernetes namespace and secret creation - will be handled by Helm chart"
echo "AWS credentials have been successfully created and stored in AWS Secrets Manager"

# The following kubectl commands are commented out as they depend on EKS being ready
# They will be performed by the Helm chart instead
#
# echo "Creating Kubernetes namespace if it doesn't exist..."
# kubectl create namespace $namespace --dry-run=client -o yaml | kubectl apply -f -
#
# echo "Creating Kubernetes secret with S3 credentials..."
# kubectl create secret generic aws-credentials \
#   --from-literal=credentials="$CREDENTIALS_CONTENT" \
#   --namespace $namespace \
#   --dry-run=client -o yaml | kubectl apply -f -
#
# echo "Created Kubernetes secret 'aws-credentials' in namespace '$namespace'"
echo "These credentials only have access to the S3 bucket: $bucket"
echo ""
echo "Summary of created resources:"
echo "- IAM user: $iam_user_name (with limited permissions)"
echo "- IAM policy: $policy_name (for S3 bucket access only)"
echo "- Secret in AWS Secrets Manager: $secret_name"
echo "- Kubernetes secret: aws-credentials in namespace $namespace"