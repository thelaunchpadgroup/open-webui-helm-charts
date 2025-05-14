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
  default     = ["us-east-1a", "us-east-1b"] # Using only 2 AZs to reduce costs
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t4g.micro" # Smallest available DB instance (ARM-based for cost savings)
}

variable "db_allocated_storage" {
  description = "Allocated storage for the RDS instance (in GB)"
  type        = number
  default     = 20 # Minimum required storage for gp3
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for the RDS instance (in GB)"
  type        = number
  default     = 20 # Limited auto-scaling for dev
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
  default     = ["t3a.medium"] # Using medium-sized AMD-based instances to ensure enough pod capacity
}

variable "node_disk_size" {
  description = "Disk size for the EKS nodes (in GB)"
  type        = number
  default     = 20
}

variable "desired_nodes" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1 # Single node for dev to minimize costs
}

variable "min_nodes" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1 # Keep at least one node available
}

variable "max_nodes" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2 # Allow scaling to only 2 nodes max for dev
}

variable "open_webui_version" {
  description = "Version of the Open WebUI Helm chart"
  type        = string
  default     = "6.13.0"
}

variable "use_custom_image" {
  description = "Whether to use a custom Open WebUI image instead of the official one"
  type        = bool
  default     = false
}

variable "custom_image_repository" {
  description = "Repository for the custom Open WebUI image"
  type        = string
  default     = ""
}

variable "custom_image_tag" {
  description = "Tag for the custom Open WebUI image"
  type        = string
  default     = "latest"
}

# Removed hardcoded ELB zone ID in favor of aws_elb_hosted_zone_id data source

variable "enable_waf" {
  description = "Whether to enable AWS WAF protection"
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Rate limit for requests per 5 minutes from a single IP"
  type        = number
  default     = 2000
}

variable "waf_blocked_countries" {
  description = "List of country codes to block (ISO 3166-1 alpha-2 format)"
  type        = list(string)
  default     = []  # Leave empty for no geo-blocking
}