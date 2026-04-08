set -e

sudo apt update -y
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible

# Add SSH public key so you can SSH in via bastion
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKL+xesBlZmIUxaaNKTkhHLqs89H/XzvY4a3RaLRBJCu nfnewbury@dons.usfca.edu" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys