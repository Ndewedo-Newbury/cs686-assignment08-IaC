packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  default = "us-west-2"
}

variable "instance_type" {
  default = "t3.micro"
}

source "amazon-ebs" "al2023_docker" {
  region        = var.aws_region
  instance_type = var.instance_type

  source_ami_filter {
    filters = {
      name                = "al2023-ami-*-x86_64"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  ssh_username    = "ec2-user"
  ami_name        = "cs686-docker-ami-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  ami_description = "Amazon Linux 2023 with Docker installed"

  tags = {
    Project = "cs686-assignment08"
    Base    = "AmazonLinux2023"
  }
}

build {
  sources = ["source.amazon-ebs.al2023_docker"]

  provisioner "shell" {
    script          = "install-dependencies.sh"
    execute_command = "bash '{{.Path}}'"
  }
}
