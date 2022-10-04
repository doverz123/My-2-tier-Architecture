# My 2-tier architecture in AWS to Deploy appache webserver

# 1. I will deploy a VPC with CIDR 10.0.0.0/16 with 2 public subnets with CIDR 10.0.1.0/24 and 10.0.2.0/24. Each public subnet should be in a different AZ for high availability.
# 2. I will Create 2 private subnets with CIDR ‘10.0.3.0/24’ and ‘10.0.4.0/24’ with an RDS MySQL instance (micro) in one of the subnets. Each private subnet should be in a different AZ.
# 3. I will crate A load balancer that will direct traffic to the public subnets.
# 4. And i will deploy 1 EC2 t2.micro instance in each public subnet.

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.33.0"
    }
  }
}

provider "aws" {
   region = "us-east-2"
}