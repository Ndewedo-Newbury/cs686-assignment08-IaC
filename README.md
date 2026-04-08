# cs686-assignment08-IaC

IaC project using Packer and Terraform to build and deploy 6 private Amazon Linux EC2 instances with Docker on AWS, accessible via a bastion host.

**What gets deployed:**
- VPC with public and private subnets, internet gateway, and NAT gateway
- Bastion host in the public subnet (SSH access restricted to your IP)
- 6 Docker hosts in the private subnet (accessible only through the bastion)
- Monitoring host in the private subnet running Prometheus, Grafana, and node_exporter via Docker Compose
- Security groups enforcing least-privilege access

---

## Prerequisites

Install the following tools before starting:

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) — configured with credentials (`aws configure`)
- [Packer](https://developer.hashicorp.com/packer/install) >= 1.8
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3

Your AWS credentials need permissions for: EC2, VPC, IAM (for Packer's temporary instance role).

---

## Step 1 — Clone the repository

```bash
git clone <repo-url>
cd cs686-assignment08-IaC
```

---

## Step 2 — Build the AMI with Packer

This creates an Amazon Linux 2023 AMI with Docker installed in your AWS account.

```bash
packer build packer.pkr.hcl
```

At the end of the build you will see output like:

```
--> amazon-ebs: AMIs were created:
us-west-2: ami-xxxxxxxxxxxxxxxxx
```

Copy that AMI ID for the docker instances and the ubuntu instances — you will need it in the next step.

---

## Step 3 — Configure terraform.tfvars

Open `terraform/terraform.tfvars` and set the following values:

```hcl
ami_id         = "ami-xxxxxxxxxxxxxxxxx"   # AMI ID from the Packer build (Amazon Linux 2023 + Docker)
ansible_ami    = "ami-xxxxxxxxxxxxxxxxx"   # AMI ID from the Packer build (Amazon Linux 2023 + Ansible)
my_ip          = "x.x.x.x"                 # Your public IP: curl -s ifconfig.me
public_key     = "ssh-ed25519 ..."         # Contents of your ~/.ssh/id_ed25519.pub
```

---

## Step 4 — Deploy with Terraform

```bash
cd terraform
terraform init    # downloads the AWS VPC module
terraform plan    # preview what will be created
terraform apply   # deploy (type 'yes' to confirm)
```

---

## Step 5 — SSH to ansible controller via bastion

After `terraform apply` completes, get the ssh command from the output
```bash
terraform output ansible_controller_ssh_command
```

## Step 6 - Ansible conifguration

Once in the terminal create two files:

inventory.ini containing the IPs of the instances being managed
```bash
 [amazon_linux]
  10.0.2.xx
  10.0.2.xx
  10.0.2.xx

  [ubuntu]
  10.0.2.xx
  10.0.2.xx
  10.0.2.xx

  [ubuntu:vars]
  ansible_user=ubuntu

  [amazon_linux:vars]
  ansible_user=ec2-user
```

ansible.cfg file 
```bash
  [defaults]                                                                                                                                                                                     
  inventory = ~/inventory.ini                                                                                                                                                                    
  remote_user = ec2-user                                                                                                                                                                         
  private_key_file = ~/.ssh/id_ed25519                                                                                                                                                           
  host_key_checking = False  
```

Then git clone this repo in order to get the ansible/11_assignment.yml playbook

On local machine run:
```bash
terraform output playbook_repo_url
```

On ansible controller run (HTTPS):
```bash
git clone <repo-url>
git checkout 11assignment
```

On your local machine run:
```bash
scp -J ec2-user@<bastion_ip> ~/.ssh/id_ed25519 ec2-user@<ansible_controller_ip>:~/.ssh/id_ed25519
```
replacing the placeholders with the terraform output values

Back on the ansible controller, in the home directory, run:
```bash
cd ~
ansible-playbook -i ~/inventory.ini cs686-assignment08-IaC/ansible/11_assignment.yml 
```

---

## Cleanup

To destroy all AWS resources created by Terraform:

```bash
cd terraform
terraform destroy
```

To delete the AMI and its snapshot from your AWS account:

```bash
# Deregister the AMI
aws ec2 deregister-image --image-id ami-xxxxxxxxxxxxxxxxx --region us-west-2

# Find and delete the associated snapshot
aws ec2 describe-snapshots --owner-ids self --region us-west-2 \
  --query "Snapshots[?Description contains 'cs686-docker-ami'].SnapshotId" \
  --output text | xargs -I {} aws ec2 delete-snapshot --snapshot-id {} --region us-west-2
```

---

## Project structure

```
.
├── packer.pkr.hcl           # Packer build config — creates the Docker AMI
├── install-docker.sh        # Provisioning script run by Packer inside the AMI for docker
├── install-ansible.sh        # Provisioning script run by Packer inside the AMI for ansible
└── terraform/
    ├── main.tf              # VPC module, security groups, 6 private EC2 instances
    ├── bastion.tf           # Bastion host in the public subnet
    ├── variables.tf         # Input variable declarations
    ├── outputs.tf           # Bastion IP, private IPs, ansible controller IP, SSH commands
    └── terraform.tfvars     # Variable values (ami_id, my_ip, public_key)
```
