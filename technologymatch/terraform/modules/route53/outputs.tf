output "certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = aws_acm_certificate.cert.arn
}

output "domain_name" {
  description = "The fully qualified domain name"
  value       = "${var.subdomain}.${var.domain_name}"
}