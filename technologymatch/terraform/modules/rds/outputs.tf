output "db_instance_endpoint" {
  description = "The connection endpoint for the database"
  value       = aws_db_instance.postgres.endpoint
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.postgres.address
}

output "db_instance_port" {
  description = "The port of the RDS instance"
  value       = aws_db_instance.postgres.port
}

output "db_instance_name" {
  description = "The name of the database"
  value       = aws_db_instance.postgres.db_name
}

output "db_instance_username" {
  description = "The username for the database"
  value       = aws_db_instance.postgres.username
}

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.postgres.id
}

output "db_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing the database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "connection_string" {
  description = "The connection string for the database"
  value       = "postgresql://${aws_db_instance.postgres.username}:${var.create_random_password ? random_password.db_password.result : var.db_password}@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.db_name}"
  sensitive   = true
}