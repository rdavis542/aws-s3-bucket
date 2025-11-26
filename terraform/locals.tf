# locals.tf - Local Values for AWS Infrastructure
# This file contains local values derived from data sources for easy reference
# across Terraform configurations

locals {
  # Region and Account Information
  region             = data.aws_region.current.name
  account_id         = data.aws_caller_identity.current.account_id
  availability_zones = data.aws_availability_zones.available.names

  # VPC Information
  vpc_id         = data.aws_vpc.selected.id
  vpc_cidr_block = data.aws_vpc.selected.cidr_block
  vpc_name       = "vpc-east-1"

  # Public Subnets
  public_subnets = {
    a = {
      id                = data.aws_subnet.public-subnet-a.id
      cidr_block        = data.aws_subnet.public-subnet-a.cidr_block
      availability_zone = data.aws_subnet.public-subnet-a.availability_zone
      name              = "public-subnet-a"
    }
    b = {
      id                = data.aws_subnet.public-subnet-b.id
      cidr_block        = data.aws_subnet.public-subnet-b.cidr_block
      availability_zone = data.aws_subnet.public-subnet-b.availability_zone
      name              = "public-subnet-b"
    }
  }

  # Private Subnets
  private_subnets = {
    a = {
      id                = data.aws_subnet.private-subnet-a.id
      cidr_block        = data.aws_subnet.private-subnet-a.cidr_block
      availability_zone = data.aws_subnet.private-subnet-a.availability_zone
      name              = "private-subnet-a"
    }
    b = {
      id                = data.aws_subnet.private-subnet-b.id
      cidr_block        = data.aws_subnet.private-subnet-b.cidr_block
      availability_zone = data.aws_subnet.private-subnet-b.availability_zone
      name              = "private-subnet-b"
    }
  }

  # Subnet ID Lists (for easy iteration)
  public_subnet_ids = [
    data.aws_subnet.public-subnet-a.id,
    data.aws_subnet.public-subnet-b.id
  ]

  private_subnet_ids = [
    data.aws_subnet.private-subnet-a.id,
    data.aws_subnet.private-subnet-b.id
  ]

  all_subnet_ids = concat(local.public_subnet_ids, local.private_subnet_ids)

  # Subnet mappings by availability zone
  public_subnets_by_az = {
    (data.aws_subnet.public-subnet-a.availability_zone)  = data.aws_subnet.public-subnet-a.id
    (data.aws_subnet.public-subnet-b.availability_zone)  = data.aws_subnet.public-subnet-b.id
  }

  private_subnets_by_az = {
    (data.aws_subnet.private-subnet-a.availability_zone) = data.aws_subnet.private-subnet-a.id
    (data.aws_subnet.private-subnet-b.availability_zone) = data.aws_subnet.private-subnet-b.id
  }

  # AMI Information
  amazon_linux_ami = {
    id            = data.aws_ami.amazon_linux.id
    name          = data.aws_ami.amazon_linux.name
    description   = data.aws_ami.amazon_linux.description
    creation_date = data.aws_ami.amazon_linux.creation_date
    architecture  = data.aws_ami.amazon_linux.architecture
    owner_id      = data.aws_ami.amazon_linux.owner_id
  }

  # Common tags for consistent resource tagging
  common_tags = {
    Environment   = terraform.workspace
    Project       = "infrastructure"
    ManagedBy     = "Terraform"
    Region        = local.region
    VPC           = local.vpc_name
  }

  # Environment-specific configurations
  environment_config = {
    name_prefix = "${terraform.workspace}-"
    
    # Common instance types by use case
    instance_types = {
      micro  = "t3.micro"
      small  = "t3.small"
      medium = "t3.medium"
      large  = "t3.large"
    }
    
    # Common ports
    ports = {
      http    = 80
      https   = 443
      ssh     = 22
      mysql   = 3306
      postgres = 5432
      redis   = 6379
    }
  }

  # Network configuration helpers
  network = {
    vpc_id              = local.vpc_id
    public_subnet_ids   = local.public_subnet_ids
    private_subnet_ids  = local.private_subnet_ids
    availability_zones  = local.availability_zones
    
    # First available subnets (useful for single-AZ resources)
    first_public_subnet  = local.public_subnet_ids[0]
    first_private_subnet = local.private_subnet_ids[0]
    
    # Subnet count for validation
    public_subnet_count  = length(local.public_subnet_ids)
    private_subnet_count = length(local.private_subnet_ids)
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    
    # Install SSM Agent (usually pre-installed on Amazon Linux 2)
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    
    # Install sample web server for port forwarding demo
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    
    # Create a simple test page
    echo "<h1>Hello from EC2 via SSM Port Forwarding!</h1>" > /var/www/html/index.html
    echo "<p>Server: $(hostname)</p>" >> /var/www/html/index.html
    echo "<p>Date: $(date)</p>" >> /var/www/html/index.html
    
    # Install MySQL for database port forwarding example
    yum install -y mariadb-server
    systemctl enable mariadb
    systemctl start mariadb
    
    # Set up a test database
    mysql -e "CREATE DATABASE testdb;"
    mysql -e "CREATE USER 'testuser'@'localhost' IDENTIFIED BY 'testpass';"
    mysql -e "GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Install some additional useful tools
    yum install -y htop nano git
    EOF
  )
}
