terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  # backend "s3" {
  #   bucket = "my-terraform-state-bucket"
  #   key    = "devops-assignment/terraform.tfstate"
  #   region = var.aws_region
  # }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = merge({
    Name = var.name_prefix
  }, var.tags)
}

# Lookup AMI if not provided
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

module "network" {
  source = "./modules/network"

  name_prefix   = var.name_prefix
  vpc_cidr      = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  aws_region     = var.aws_region
  tags           = local.common_tags
  app_port       = var.app_port
}

module "asg" {
  source = "./modules/asg"

  name_prefix       = var.name_prefix
  instance_type     = var.instance_type
  instance_ami      = var.instance_ami != "" ? var.instance_ami : data.aws_ami.amazon_linux_2.id
  user_data         = templatefile("${path.module}/user_data.tpl", { app_port = var.app_port })
  public_subnets    = module.network.public_subnets
  private_subnets   = module.network.private_subnets
  vpc_id            = module.network.vpc_id
  ec2_security_group = module.network.ec2_security_group
  alb_security_group = module.network.alb_security_group
  app_port          = var.app_port
  desired_capacity  = var.desired_capacity
  min_size          = var.min_size
  max_size          = var.max_size
  key_name          = var.key_name
  tags              = local.common_tags
}