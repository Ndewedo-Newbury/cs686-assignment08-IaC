variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "ami_id" {
  description = "AMI ID built by Packer (cs686-docker-ami)"
  type        = string
}

variable "bastion_ami_id" {
  description = "AMI ID for the bastion host (use a standard Amazon Linux 2 AMI for your region)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "my_ip" {
  description = "Your public IP address — bastion port 22 will only accept this IP (e.g. 203.0.113.5)"
  type        = string
}

variable "public_key" {
  description = "SSH public key to use for the bastion host key pair"
  type        = string
}

variable "bastion_prefix" {
  description = "Name prefix for bastion host resources"
  type        = string
  default     = "cs686-bastion"
}

variable "resource_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "cs686-assignment11"
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "cs686-assignment11"
}

variable "ansible_controller_ami_id" {
  description = "AMI ID built by Packer for the Ansible Controller (cs686-ansible-controller-ami)"
  type        = string
}

variable "playbook_repo_url" {
  description = "HTTPS URL of the Git repo containing Ansible playbooks (e.g. https://github.com/org/repo.git)"
  type        = string
}

variable "playbook_branch" {
  description = "Git branch to clone for Ansible playbooks"
  type        = string
  default     = "11assignment"
}

