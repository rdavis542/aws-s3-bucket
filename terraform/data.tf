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