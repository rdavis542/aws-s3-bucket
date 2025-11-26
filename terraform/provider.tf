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

}

# Configure the primary region provider
provider "aws" {
  region = "us-east-2"
  alias  = "primary"
}

# Configure the replica region provider
provider "aws" {
  region = "us-west-2"
  alias  = "replica"
}