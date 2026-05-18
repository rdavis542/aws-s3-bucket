# Resource-specific tags (default_tags handles common tags)

locals {
  source_bucket_tags = {
    Name        = "Terraform State Bucket Source"
    Replication = "source"
    Purpose     = "terraform-state-storage"
  }

  destination_bucket_tags = {
    Name        = "Terraform State Bucket Destination"
    Replication = "destination"
    Purpose     = "terraform-state-storage"
  }

  dynamodb_tags = {
    Name    = "Terraform State Lock Table"
    Purpose = "terraform-state-locking"
  }

  iam_tags = {
    Name    = "S3 Replication Role"
    Purpose = "terraform-state-replication"
  }
}
