aws_region          = "us-west-2"
instance_type       = "t3.micro"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
project_name        = "cs686-assignment08"
bastion_prefix      = "cs686-bastion"

# Standard Amazon Linux 2 AMI for the bastion host (us-west-2)
bastion_ami_id = "ami-0534a0fd33c655746"

# Custom AMI built by Packer (Amazon Linux 2023 + Docker)
ami_id = "ami-04731c90409af234b"

# Custom AMI built by Packer (Amazon Linux 2023 + Ansible) — update after running packer build
ansible_controller_ami_id = ""

# HTTPS URL of the Git repo containing Ansible playbooks
playbook_repo_url = "https://github.com/<your-org>/<your-repo>.git"

# Your public IP — run: curl -s ifconfig.me
my_ip = "138.202.26.169"

# Paste your SSH public key here (e.g. contents of ~/.ssh/id_ed25519.pub)
public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKL+xesBlZmIUxaaNKTkhHLqs89H/XzvY4a3RaLRBJCu nfnewbury@dons.usfca.edu"

resource_tags = {
  Project = "cs686-assignment08"
}
