aws_region          = "us-west-2"
instance_type       = "t2.micro"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
project_name        = "cs686-assignment08"
bastion_prefix      = "cs686-bastion"

# Set this after running: packer build packer.json
# The AMI ID will be printed at the end of the Packer build
ami_id = "ami-REPLACE_AFTER_PACKER_BUILD"

# Your public IP — run: curl -s ifconfig.me
my_ip = "73.71.103.28"

# Paste your SSH public key here (e.g. contents of ~/.ssh/id_ed25519.pub)
public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKL+xesBlZmIUxaaNKTkhHLqs89H/XzvY4a3RaLRBJCu nfnewbury@dons.usfca.edu"

resource_tags = {
  Project = "cs686-assignment08"
}
