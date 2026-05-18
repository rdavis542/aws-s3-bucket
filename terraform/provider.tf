terraform {
  required_version = ">=1.10.0"
  required_providers {
    aws = {
      version = ">= 4.0.0"
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket  = "tf-state-replication-source-350726165848"
    key     = "terraform-s3-bucket.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}


provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "development"
      Project     = "aws-s3-bucket"
      ManagedBy   = "Terraform"
      Repository  = "aws-s3-bucket"
      Owner       = "ryan_davis542@outlook.com"
      CostCenter  = "Personal"
      Region      = var.region
    }
  }
}

# Configure the primary region provider
provider "aws" {
  region = "us-east-2"
  alias  = "primary"

  default_tags {
    tags = {
      Environment = "development"
      Project     = "aws-s3-bucket"
      ManagedBy   = "Terraform"
      Repository  = "aws-s3-bucket"
      Owner       = "ryan_davis542@outlook.com"
      CostCenter  = "Personal"
      Region      = "us-east-2"
    }
  }
}

# Configure the replica region provider
provider "aws" {
  region = "us-west-2"
  alias  = "replica"

  default_tags {
    tags = {
      Environment = "development"
      Project     = "aws-s3-bucket"
      ManagedBy   = "Terraform"
      Repository  = "aws-s3-bucket"
      Owner       = "ryan_davis542@outlook.com"
      CostCenter  = "Personal"
      Region      = "us-west-2"
    }
  }
}