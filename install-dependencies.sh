#!/bin/bash
set -e

# Update system
sudo dnf update -y

# Install Docker
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

# Add SSH public key
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKL+xesBlZmIUxaaNKTkhHLqs89H/XzvY4a3RaLRBJCu nfnewbury@dons.usfca.edu" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
