terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.project_name
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a"]
  public_subnets  = [var.public_subnet_cidr]
  private_subnets = [var.private_subnet_cidr]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    Project = var.project_name
  }
}

resource "aws_security_group" "private_instances" {
  name        = "${var.project_name}-private-sg"
  description = "Allow SSH only from bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [module.bastion.bastion_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-private-sg"
    Project = var.project_name
  }
}

resource "aws_instance" "docker_host" {
  count = 6

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.private_subnets[0]
  vpc_security_group_ids      = [aws_security_group.private_instances.id]
  associate_public_ip_address = false

  tags = {
    Name    = "${var.project_name}-docker-host-${count.index + 1}"
    Project = var.project_name
  }
}
