# Bootstrap Terraform configuration for state backend infrastructure
# This creates the S3 buckets and DynamoDB table needed for Terraform remote state

terraform {
  required_version = ">=1.1.0"
  required_providers {
    aws = {
      version = ">= 4.0.0"
      source  = "hashicorp/aws"
    }
  }

  # This bootstrap config uses local state
  # After creating the buckets, migrate this state to S3
}

# Default provider (required)
provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Environment = "development"
      Project     = "terraform-state-backend"
      ManagedBy   = "Terraform"
      Repository  = "aws-s3-bucket"
      Owner       = "ryan_davis542@outlook.com"
      CostCenter  = "Personal"
    }
  }
}

# Primary region provider
provider "aws" {
  region = var.primary_region
  alias  = "primary"

  default_tags {
    tags = {
      Environment = "development"
      Project     = "terraform-state-backend"
      ManagedBy   = "Terraform"
      Repository  = "aws-s3-bucket"
      Owner       = "ryan_davis542@outlook.com"
      CostCenter  = "Personal"
    }
  }
}

# Replica region provider
provider "aws" {
  region = var.replica_region
  alias  = "replica"

  default_tags {
    tags = {
      Environment = "development"
      Project     = "terraform-state-backend"
      ManagedBy   = "Terraform"
      Repository  = "aws-s3-bucket"
      Owner       = "ryan_davis542@outlook.com"
      CostCenter  = "Personal"
    }
  }
}

data "aws_caller_identity" "current" {}

# Source S3 bucket for Terraform state (primary region)
module "source_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.15"

  providers = {
    aws = aws.primary
  }

  bucket = "${var.bucket_prefix}-source-${data.aws_caller_identity.current.account_id}"

  # Enable versioning (required for replication and state file safety)
  versioning = {
    enabled = true
  }

  # Replication configuration
  replication_configuration = {
    role = aws_iam_role.replication.arn

    rules = [
      {
        id       = "replicate-all-state-files"
        status   = "Enabled"
        priority = 10

        filter = {
          prefix = ""
        }

        delete_marker_replication = true

        destination = {
          bucket        = module.destination_bucket.s3_bucket_arn
          storage_class = "STANDARD"

          replica_modifications = {
            status = "Enabled"
          }
        }
      }
    ]
  }

  depends_on = [module.destination_bucket]

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  # Block public access (critical for state files!)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.source_bucket_tags

  # Ensure no empty tag values
  attach_elb_log_delivery_policy        = false
  attach_lb_log_delivery_policy         = false
  attach_deny_insecure_transport_policy = false
  attach_require_latest_tls_policy      = false
}

# Destination bucket in replica region
module "destination_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.15"

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
      bucket_key_enabled = true
    }
  }

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.destination_bucket_tags

  # Ensure no empty tag values
  attach_elb_log_delivery_policy        = false
  attach_lb_log_delivery_policy         = false
  attach_deny_insecure_transport_policy = false
  attach_require_latest_tls_policy      = false
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  provider = aws.primary

  name         = "${var.bucket_prefix}-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = local.dynamodb_tags
}

# IAM role for S3 replication
resource "aws_iam_role" "replication" {
  provider = aws.primary

  name = "${var.bucket_prefix}-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = local.iam_tags
}

resource "aws_iam_role_policy" "replication" {
  provider = aws.primary

  name = "${var.bucket_prefix}-replication-policy"
  role = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          module.source_bucket.s3_bucket_arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "${module.source_bucket.s3_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          "${module.destination_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}
