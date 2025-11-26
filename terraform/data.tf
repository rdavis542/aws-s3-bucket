# data.tf - AWS Infrastructure Data Sources
# This file contains data sources to retrieve consistent AWS infrastructure information
# across Terraform projects

# Get current AWS region
data "aws_region" "current" {}

# Get current AWS caller identity (account info)
data "aws_caller_identity" "current" {}

# Get all available availability zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["vpc-east-1"]
  }
}

data "aws_subnet" "public-subnet-a" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet-a"]
  }
}

data "aws_subnet" "public-subnet-b" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet-b"]
  }
}

data "aws_subnet" "private-subnet-a" {
  filter {
    name   = "tag:Name"
    values = ["private-subnet-a"]
  }
}

data "aws_subnet" "private-subnet-b" {
  filter {
    name   = "tag:Name"
    values = ["private-subnet-b"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

}
