terraform {
  required_version = ">=1.1.0"
  required_providers {
    aws = {
      version = ">= 4.0.0"
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket  = "tfstategit"
    key     = "s3-bucket-terraform.tfstate"
    region  =  "us-east-1"
    encrypt = true
  }
}


provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "development"
      Project     = "aws-s3-bucket"
      ManagedBy   = "Terraform"
      Repository  = "aws-s3-bucket"
      Owner       = "ryan_davis542@outlook.com"
      CostCenter  = "Personal"
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
    }
  }
}