variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.medium" # Higher instance class for production
}

variable "db_allocated_storage" {
  description = "Allocated storage for the RDS instance (in GB)"
  type        = number
  default     = 50 # More storage for production
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for the RDS instance (in GB)"
  type        = number
  default     = 200 # Higher ceiling for production
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "openwebui"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "openwebui"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_instance_types" {
  description = "Instance types to use for the EKS nodes"
  type        = list(string)
  default     = ["t3.large"] # Larger instances for production
}

variable "node_disk_size" {
  description = "Disk size for the EKS nodes (in GB)"
  type        = number
  default     = 50 # More storage for production
}

variable "desired_nodes" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3 # More nodes for production
}

variable "min_nodes" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2 # Higher minimum for high availability
}

variable "max_nodes" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5 # Higher maximum for scalability
}

variable "open_webui_version" {
  description = "Version of the Open WebUI Helm chart"
  type        = string
  default     = "6.13.0"
}

variable "s3_access_key" {
  description = "AWS access key for S3 access"
  type        = string
  sensitive   = true
  # No default value for security reasons - must be provided via terraform.tfvars
}

variable "s3_secret_key" {
  description = "AWS secret key for S3 access"
  type        = string
  sensitive   = true
  # No default value for security reasons - must be provided via terraform.tfvars
}