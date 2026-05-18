# locals.tf - Local Values for AWS Infrastructure

locals {
  # Region and Account Information
  region             = data.aws_region.current.id
  account_id         = data.aws_caller_identity.current.account_id
  availability_zones = data.aws_availability_zones.available.names

  # Environment-specific configurations
  environment_config = {
    name_prefix = "${terraform.workspace}-"
  }
}
