variable "domain_name" {
  description = "The domain name to use for Route53 records"
  type        = string
}

variable "subdomain" {
  description = "The subdomain to use for Route53 records"
  type        = string
}

variable "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  type        = string
}

variable "load_balancer_zone_id" {
  description = "The zone ID of the load balancer"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "create_dns_record" {
  description = "Whether to create the DNS record"
  type        = bool
  default     = true
}