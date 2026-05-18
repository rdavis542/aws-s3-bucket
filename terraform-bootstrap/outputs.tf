output "source_bucket_name" {
  description = "Name of the source S3 bucket for Terraform state"
  value       = module.source_bucket.s3_bucket_id
}

output "source_bucket_arn" {
  description = "ARN of the source S3 bucket"
  value       = module.source_bucket.s3_bucket_arn
}

output "destination_bucket_name" {
  description = "Name of the destination S3 bucket (replica)"
  value       = module.destination_bucket.s3_bucket_id
}

output "destination_bucket_arn" {
  description = "ARN of the destination S3 bucket"
  value       = module.destination_bucket.s3_bucket_arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.terraform_state_lock.arn
}

output "backend_config" {
  description = "Terraform backend configuration to use in your projects"
  value = <<-EOT

    # Add this to your terraform block:
    terraform {
      backend "s3" {
        bucket         = "${module.source_bucket.s3_bucket_id}"
        key            = "path/to/your/terraform.tfstate"  # Change this per project
        region         = "${var.primary_region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_state_lock.name}"
        encrypt        = true
      }
    }
  EOT
}

output "primary_region" {
  description = "Primary region where state bucket is located"
  value       = var.primary_region
}

output "replica_region" {
  description = "Replica region for disaster recovery"
  value       = var.replica_region
}
