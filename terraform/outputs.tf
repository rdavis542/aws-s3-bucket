output "source_bucket_id" {
  description = "ID of the source bucket"
  value       = module.source_bucket.s3_bucket_id
}

output "source_bucket_arn" {
  description = "ARN of the source bucket"
  value       = module.source_bucket.s3_bucket_arn
}

output "destination_bucket_id" {
  description = "ID of the destination bucket"
  value       = module.destination_bucket.s3_bucket_id
}

output "destination_bucket_arn" {
  description = "ARN of the destination bucket"
  value       = module.destination_bucket.s3_bucket_arn
}

output "replication_role_arn" {
  description = "ARN of the replication IAM role"
  value       = aws_iam_role.replication.arn
}