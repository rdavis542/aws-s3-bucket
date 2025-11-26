# locals.tf - Local Values for AWS Infrastructure
# This file contains local values derived from data sources for easy reference
# across Terraform configurations

locals {
  # Region and Account Information
  region             = data.aws_region.current.id
  account_id         = data.aws_caller_identity.current.account_id
  availability_zones = data.aws_availability_zones.available.names

 
  # Common tags for consistent resource tagging
  common_tags = {
    Environment   = terraform.workspace
    Project       = "infrastructure"
    ManagedBy     = "Terraform"
    Region        = local.region
  }

  # Environment-specific configurations
  environment_config = {
    name_prefix = "${terraform.workspace}-"
  }

  
}
