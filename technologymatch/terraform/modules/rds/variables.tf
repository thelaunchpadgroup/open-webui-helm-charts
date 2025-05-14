variable "prefix" {
  description = "Prefix to add to all resources"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS instance"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID for the database"
  type        = string
}

variable "instance_class" {
  description = "The instance type for the RDS instance"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "The amount of storage to allocate (in GiB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "The maximum storage to allocate for autoscaling (in GiB)"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
  default     = "openwebui"
}

variable "db_username" {
  description = "Username for the RDS instance"
  type        = string
  default     = "openwebui"
}

variable "db_password" {
  description = "Password for the RDS instance (only used if create_random_password is false)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "create_random_password" {
  description = "Whether to create a random password for the RDS instance"
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Whether to create a multi-AZ RDS instance"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The number of days to keep backups"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Whether to skip taking a final snapshot when destroying the database"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}