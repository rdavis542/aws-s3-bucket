module "source_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  providers = {
    aws = aws.primary
  }

  bucket = "${var.bucket_prefix}-source-${data.aws_caller_identity.current.account_id}"
  
  # Enable versioning (required for replication)
  versioning = {
    enabled = true
  }

  # Replication configuration
  replication_configuration = {
    role = aws_iam_role.replication.arn

    rules = [
      {
        id       = "replicate-all"
        status   = "Enabled"
        priority = 10

        filter = {
          prefix = ""
        }

        delete_marker_replication = false

        destination = {
          bucket        = module.destination_bucket.s3_bucket_arn
          storage_class = "STANDARD"
          
          # Optional: Enable replica modification sync
          replica_modifications = {
            status = "Enabled"
          }
        }
      }
    ]
  }

# Explicit dependency to ensure destination bucket is fully created first
  depends_on = [module.destination_bucket]

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "Source Bucket"
    Environment = "production"
    Replication = "source"
  }
}

# Destination bucket in replica region
module "destination_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  providers = {
    aws = aws.replica
  }

  bucket = "${var.bucket_prefix}-destination-${data.aws_caller_identity.current.account_id}"
  
  # Enable versioning (required for replication)
  versioning = {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "Destination Bucket"
    Environment = "production"
    Replication = "destination"
  }
}
