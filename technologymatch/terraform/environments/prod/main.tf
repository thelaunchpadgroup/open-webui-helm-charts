provider "aws" {
  region  = var.aws_region
  profile = "Technologymatch"
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

locals {
  prefix = "openwebui-prod"
  tags = {
    Environment = "prod"
    Project     = "open-webui"
    ManagedBy   = "terraform"
  }
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
  bucket_name = "technologymatch-open-webui-prod"
  tags        = local.tags
}

module "rds" {
  source = "../../modules/rds"

  prefix                = local.prefix
  environment           = "prod"
  subnet_ids            = module.vpc.database_subnet_ids
  db_security_group_id  = module.vpc.database_security_group_id
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  db_name               = var.db_name
  db_username           = var.db_username
  multi_az              = true # For production, enable multi-AZ for high availability
  backup_retention_period = 14 # Longer backup retention for production
  skip_final_snapshot   = false # Take final snapshot for prod
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
  capacity_type            = "ON_DEMAND" # Use on-demand instances for production reliability
  desired_nodes            = var.desired_nodes
  min_nodes                = var.min_nodes
  max_nodes                = var.max_nodes
  tags                     = local.tags
}

# Create Route53 configuration for domain
module "route53" {
  source = "../../modules/route53"

  domain_name           = "technologymatch.com"
  subdomain             = "ai"
  load_balancer_dns_name = "" # This will need to be filled in after the ALB is created
  load_balancer_zone_id = "" # This will need to be filled in after the ALB is created
  tags                 = local.tags
}

# Get the OpenAI API key from AWS Secrets Manager
data "aws_secretsmanager_secret" "openai_api_key" {
  name = "openwebui-prod/openai-api-key"
}

data "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id = data.aws_secretsmanager_secret.openai_api_key.id
}

# Deploy OpenWebUI Helm chart
resource "helm_release" "open_webui" {
  name       = "open-webui"
  repository = "https://helm.openwebui.com/"
  chart      = "open-webui"
  namespace  = "open-webui-prod"
  create_namespace = true
  version    = var.open_webui_version
  timeout    = 900 # Increase timeout to 15 minutes instead of default 5 minutes

  values = [
    templatefile("${path.module}/values.yaml", {
      s3_access_key         = var.s3_access_key
      s3_secret_key         = var.s3_secret_key
      s3_region             = var.aws_region
      s3_bucket             = module.s3.bucket_id
      db_connection_string  = module.rds.connection_string
      domain_name           = "ai.technologymatch.com"
      cert_arn              = module.route53.certificate_arn
      openai_api_key        = data.aws_secretsmanager_secret_version.openai_api_key.secret_string
    })
  ]

  depends_on = [
    module.eks,
    module.rds,
    module.s3
  ]
}