provider "aws" {
  region  = var.aws_region
  profile = "Technologymatch"
}

provider "null" {
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", "Technologymatch"]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", "Technologymatch"]
    command     = "aws"
  }
}

locals {
  # Using a unique identifier to avoid conflicts with resources still being deleted
  unique_suffix = "v6"
  prefix = "openwebui-dev-${local.unique_suffix}"
  tags = {
    Environment = "dev"
    Project     = "open-webui"
    ManagedBy   = "terraform"
    Deployment  = local.unique_suffix
  }
  # Define common namespace for all resources
  namespace = "open-webui-dev-${local.unique_suffix}"
  # Service name for looking up the load balancer
  service_name = "open-webui"
}

module "vpc" {
  source = "../../modules/vpc"

  prefix             = local.prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  tags               = local.tags
}

module "s3" {
  source = "../../modules/s3"

  prefix      = local.prefix
  bucket_name = "technologymatch-open-webui-dev-${local.unique_suffix}"
  tags        = local.tags
}

# Create AWS credentials after S3 bucket and before Helm deployment
resource "null_resource" "create_aws_credentials" {
  provisioner "local-exec" {
    command = "${path.module}/create-aws-credentials-secret.sh"
  }

  depends_on = [
    module.s3,
    module.eks
  ]
}

module "rds" {
  source = "../../modules/rds"

  prefix                = local.prefix
  environment           = "dev"
  subnet_ids            = module.vpc.database_subnet_ids
  db_security_group_id  = module.vpc.database_security_group_id
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  db_name               = var.db_name
  db_username           = var.db_username
  multi_az              = false
  skip_final_snapshot   = true # For dev, we don't need a final snapshot
  tags                  = local.tags
}

module "eks" {
  source = "../../modules/eks"

  prefix                   = local.prefix
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids       = module.vpc.private_subnet_ids
  database_security_group_id = module.vpc.database_security_group_id
  s3_access_policy_arn     = module.s3.s3_access_policy_arn
  kubernetes_version       = var.kubernetes_version
  endpoint_public_access   = true
  node_instance_types      = var.node_instance_types
  node_disk_size           = var.node_disk_size
  capacity_type            = "SPOT" # Use spot instances for dev to save significantly on cost
  desired_nodes            = var.desired_nodes
  min_nodes                = var.min_nodes
  max_nodes                = var.max_nodes
  tags                     = local.tags
}

# Create ACM certificate before the helm deployment
module "acm" {
  source = "../../modules/route53"

  domain_name            = "technologymatch.com"
  subdomain              = "ai-dev"
  # Placeholders since the load balancer doesn't exist yet
  load_balancer_dns_name = "placeholder.elb.amazonaws.com"
  load_balancer_zone_id  = "placeholder"
  create_dns_record      = false # Don't create the DNS record yet
  tags                   = local.tags
}

# Get secrets from AWS Secrets Manager
data "aws_secretsmanager_secret" "openai_api_key" {
  name = "openwebui-dev/openai-api-key"
}

data "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id = data.aws_secretsmanager_secret.openai_api_key.id
}

data "aws_secretsmanager_secret" "s3_credentials" {
  name = "openwebui-dev-${local.unique_suffix}/s3-credentials"
  depends_on = [null_resource.create_aws_credentials]
}

data "aws_secretsmanager_secret_version" "s3_credentials" {
  secret_id = data.aws_secretsmanager_secret.s3_credentials.id
  depends_on = [null_resource.create_aws_credentials]
}

locals {
  s3_creds = jsondecode(data.aws_secretsmanager_secret_version.s3_credentials.secret_string)
}

# Create Kubernetes namespace before helm deployment to ensure it exists
resource "kubernetes_namespace" "open_webui" {
  metadata {
    name = local.namespace
    labels = {
      name        = local.namespace
      environment = "dev"
      project     = "open-webui"
    }
  }

  depends_on = [
    module.eks
  ]
}

# Wait for AWS Load Balancer Controller to be ready
resource "time_sleep" "wait_for_lb_controller" {
  depends_on = [module.eks]
  create_duration = "300s" # Wait 5 minutes for the controller to be fully ready
}

# Deploy OpenWebUI Helm chart
resource "helm_release" "open_webui" {
  name             = "open-webui-${local.unique_suffix}"
  repository       = "https://helm.openwebui.com/"
  chart            = "open-webui"
  namespace        = local.namespace
  create_namespace = false # We already created the namespace above
  version          = var.open_webui_version
  timeout          = 2400 # Increase timeout to 40 minutes to allow plenty of time for resources to provision
  wait             = true
  wait_for_jobs    = true
  atomic           = true # If the installation fails, roll back all resources
  cleanup_on_fail  = true # Clean up resources on failed install
  force_update     = true # Force recreation of resources

  values = [
    templatefile("${path.module}/values.yaml", {
      s3_access_key         = local.s3_creds.access_key
      s3_secret_key         = local.s3_creds.secret_key
      s3_region             = var.aws_region
      s3_bucket             = module.s3.bucket_id
      db_connection_string  = module.rds.connection_string
      domain_name           = "ai-dev.technologymatch.com"
      openai_api_key        = data.aws_secretsmanager_secret_version.openai_api_key.secret_string
      aws_acm_certificate_arn = module.acm.certificate_arn
      public_subnet_ids     = join(",", module.vpc.public_subnet_ids)
      use_custom_image      = var.use_custom_image
      custom_image_repository = var.custom_image_repository
      custom_image_tag      = var.custom_image_tag
    })
  ]

  depends_on = [
    module.eks,
    module.rds,
    module.s3,
    module.acm,
    null_resource.create_aws_credentials,
    kubernetes_namespace.open_webui,
    time_sleep.wait_for_lb_controller
  ]
}

# Wait for Kubernetes service to be fully available and have a load balancer
resource "time_sleep" "wait_for_lb" {
  depends_on = [helm_release.open_webui]
  create_duration = "180s" # Wait 60 seconds after Helm deployment to ensure everything is deployed
}

# Get the load balancer details directly using the Kubernetes provider
data "kubernetes_service" "open_webui" {
  metadata {
    name      = local.service_name
    namespace = local.namespace
  }

  depends_on = [
    time_sleep.wait_for_lb
  ]
}

# Get the Route53 zone
data "aws_route53_zone" "selected" {
  name         = "technologymatch.com"
  private_zone = false
}

# Get the regional ELB hosted zone ID dynamically
# Define a mapping of AWS regions to ELB zone IDs
locals {
  elb_zone_ids = {
    "us-east-1"      = "Z35SXDOTRQ7X7K"      # N. Virginia
    "us-east-2"      = "ZPQZ6S1UHFGC"        # Ohio
    "us-west-1"      = "Z368ELLRRE2KJ0"      # N. California
    "us-west-2"      = "Z1H1FL5HABSF5"       # Oregon
    "af-south-1"     = "Z268VQBMOI5EKX"      # Africa (Cape Town)
    "ap-east-1"      = "Z3DQVH9N71FHZ0"      # Asia Pacific (Hong Kong)
    "ap-south-1"     = "ZP97RAFLXTNZK"       # Asia Pacific (Mumbai)
    "ap-northeast-3" = "Z5LXEXXYW11ES"       # Asia Pacific (Osaka)
    "ap-northeast-2" = "ZWKZPGTI48KDX"       # Asia Pacific (Seoul)
    "ap-southeast-1" = "Z1LMS91P8CMLE5"      # Asia Pacific (Singapore)
    "ap-southeast-2" = "Z1GM3OXH4ZPM65"      # Asia Pacific (Sydney)
    "ap-northeast-1" = "Z14GRHDCWA56QT"      # Asia Pacific (Tokyo)
    "ca-central-1"   = "ZQSVJUPU6J1EY"       # Canada (Central)
    "eu-central-1"   = "Z215JYRZR1TBD5"      # Europe (Frankfurt)
    "eu-west-1"      = "Z32O12XQLNTSW2"      # Europe (Ireland)
    "eu-west-2"      = "ZHURV8PSTC4K8"       # Europe (London)
    "eu-south-1"     = "Z3ULH7SSC9OV64"      # Europe (Milan)
    "eu-west-3"      = "Z3Q77PNBQS71R4"      # Europe (Paris)
    "eu-north-1"     = "Z23TAZ6LKFMNIO"      # Europe (Stockholm)
    "me-south-1"     = "ZS929ML54UICD"       # Middle East (Bahrain)
    "sa-east-1"      = "Z2P70J7HTTTPLU"      # South America (São Paulo)
  }
  
  # Get the ELB zone ID for the current region
  elb_zone_id = lookup(local.elb_zone_ids, var.aws_region, "Z35SXDOTRQ7X7K") # Default to us-east-1 if not found
}

# Get the ingress details for the application
data "kubernetes_ingress" "open_webui" {
  metadata {
    name      = "open-webui"
    namespace = local.namespace
  }

  depends_on = [
    time_sleep.wait_for_lb
  ]
}

# Create a CNAME record pointing to the ingress ALB
resource "aws_route53_record" "open_webui" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "ai-dev"
  type    = "CNAME"
  ttl     = 300
  records = [data.kubernetes_ingress.open_webui.status[0].load_balancer[0].ingress[0].hostname]

  # Explicit dependency to ensure we only try to create the record after the load balancer exists
  depends_on = [
    data.kubernetes_ingress.open_webui,
    time_sleep.wait_for_lb
  ]

  # Use a lifecycle hook to create a new record before destroying the old one
  lifecycle {
    create_before_destroy = true
  }
}

# Output useful information
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region} --profile Technologymatch"
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "s3_bucket_name" {
  value = module.s3.bucket_id
}

output "db_secret_arn" {
  value = module.rds.db_secret_arn
}

output "load_balancer_address" {
  value = try(data.kubernetes_service.open_webui.status.0.load_balancer.0.ingress.0.hostname, "not-available-yet")
  description = "The hostname of the load balancer serving the application"
}

output "application_url" {
  value = "https://ai-dev.technologymatch.com"
  description = "The URL to access the application"
}