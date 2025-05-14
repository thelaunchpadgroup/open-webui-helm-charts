resource "aws_db_subnet_group" "open_webui" {
  name       = "${var.prefix}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-subnet-group"
    }
  )
}

resource "aws_db_parameter_group" "postgres" {
  name   = "${var.prefix}-pg-new"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-pg"
    }
  )
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.prefix}-db-credentials-2025-05-12"
  description = "RDS credentials for Open WebUI"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.create_random_password ? random_password.db_password.result : var.db_password
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = 5432
    dbname   = var.db_name
    dbInstanceIdentifier = aws_db_instance.postgres.id
  })
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.prefix}-postgres-new"
  engine                 = "postgres"
  engine_version         = "14"
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  storage_type           = "gp2" # Use gp2 instead of gp3 as it has lower minimum storage requirements
  storage_encrypted      = true
  
  db_name                = var.db_name
  username               = var.db_username
  password               = var.create_random_password ? random_password.db_password.result : var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.open_webui.name
  vpc_security_group_ids = [var.db_security_group_id]
  
  parameter_group_name   = aws_db_parameter_group.postgres.name
  
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  
  multi_az               = var.multi_az
  publicly_accessible    = false
  
  # Final snapshot is important for production, but can be disabled in dev environments
  skip_final_snapshot    = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.prefix}-postgres-final-snapshot"
  
  deletion_protection    = var.environment == "prod"
  
  # Enhanced monitoring
  monitoring_interval    = 60
  monitoring_role_arn    = aws_iam_role.rds_monitoring_role.arn
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-postgres"
    }
  )
}

resource "aws_iam_role" "rds_monitoring_role" {
  name = "${var.prefix}-rds-monitoring-role-new"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_role_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}