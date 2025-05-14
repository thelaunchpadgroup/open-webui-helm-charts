variable "prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer to associate with the WAF"
  type        = string
}

variable "rate_limit" {
  description = "Rate limit for requests per 5 minutes from a single IP"
  type        = number
  default     = 2000  # Adjust based on expected legitimate traffic
}

variable "blocked_countries" {
  description = "List of country codes to block (ISO 3166-1 alpha-2 format)"
  type        = list(string)
  default     = []  # Example: ["RU", "CN", "IR"]
}

variable "enable_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}