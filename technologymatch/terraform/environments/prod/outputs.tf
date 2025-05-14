output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS API server"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.s3.bucket_id
}

output "rds_endpoint" {
  description = "The connection endpoint for the database"
  value       = module.rds.db_instance_endpoint
}

output "db_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing the database credentials"
  value       = module.rds.db_secret_arn
}

output "domain_name" {
  description = "The domain name for the application"
  value       = module.route53.domain_name
}

output "certificate_arn" {
  description = "The ARN of the SSL certificate"
  value       = module.route53.certificate_arn
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region} --profile Technologymatch"
}