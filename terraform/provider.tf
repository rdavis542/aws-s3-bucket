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
    region  =  var.region
    encrypt = true
  }
}


provider "aws" {

  region = var.region

}