resource "aws_s3_bucket" "open_webui_bucket" {
  bucket = var.bucket_name
  
  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

resource "aws_s3_bucket_ownership_controls" "open_webui_bucket_ownership" {
  bucket = aws_s3_bucket.open_webui_bucket.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "open_webui_bucket_public_access_block" {
  bucket = aws_s3_bucket.open_webui_bucket.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "open_webui_bucket_versioning" {
  bucket = aws_s3_bucket.open_webui_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "open_webui_bucket_encryption" {
  bucket = aws_s3_bucket.open_webui_bucket.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM policy for EKS pods to access S3 bucket
resource "aws_iam_policy" "open_webui_s3_access" {
  name        = "${var.prefix}-s3-access-new"
  description = "Policy for Open WebUI to access S3 bucket"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.open_webui_bucket.arn,
          "${aws_s3_bucket.open_webui_bucket.arn}/*"
        ]
      }
    ]
  })
  
  tags = var.tags
}