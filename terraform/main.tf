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

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
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

resource "aws_security_group" "ansible_controller" {
  name        = "${var.project_name}-ansible-sg"
  description = "Security group for Ansible Controller"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-ansible-sg"
    Project = var.project_name
  }
}

resource "aws_security_group" "private_instances" {
  name        = "${var.project_name}-private-sg"
  description = "Allow SSH from bastion and Ansible Controller"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "SSH from Ansible Controller"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ansible_controller.id]
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

resource "aws_instance" "ubuntu" {
  count = 3

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.private_subnets[0]
  vpc_security_group_ids      = [aws_security_group.private_instances.id]
  key_name                    = aws_key_pair.bastion-key.key_name
  associate_public_ip_address = false

  tags = {
    Name    = "${var.project_name}-ubuntu-${count.index + 1}"
    Project = var.project_name
    OS      = "ubuntu"
  }
}

resource "aws_instance" "amazon_linux" {
  count = 3

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.private_subnets[0]
  vpc_security_group_ids      = [aws_security_group.private_instances.id]
  key_name                    = aws_key_pair.bastion-key.key_name
  associate_public_ip_address = false

  tags = {
    Name    = "${var.project_name}-amazon-linux-${count.index + 1}"
    Project = var.project_name
    OS      = "amazon"
  }
}

resource "aws_instance" "ansible_controller" {
  ami                         = var.ansible_controller_ami_id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.private_subnets[0]
  vpc_security_group_ids      = [aws_security_group.ansible_controller.id]
  key_name                    = aws_key_pair.bastion-key.key_name
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    git clone ${var.playbook_repo_url} /home/ec2-user/playbooks
    chown -R ec2-user:ec2-user /home/ec2-user/playbooks
  EOF

  tags = {
    Name    = "${var.project_name}-ansible-controller"
    Project = var.project_name
    Role    = "ansible-controller"
  }
}
