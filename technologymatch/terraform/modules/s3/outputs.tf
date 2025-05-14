output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.open_webui_bucket.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.open_webui_bucket.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.open_webui_bucket.bucket_regional_domain_name
}

output "s3_access_policy_arn" {
  description = "The ARN of the IAM policy for S3 access"
  value       = aws_iam_policy.open_webui_s3_access.arn
}