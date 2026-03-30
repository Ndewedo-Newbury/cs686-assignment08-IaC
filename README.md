# cs686-assignment08-IaC

IaC project using Packer and Terraform to build and deploy 6 private Amazon Linux EC2 instances with Docker on AWS, accessible via a bastion host.

**What gets deployed:**
- VPC with public and private subnets, internet gateway, and NAT gateway
- Bastion host in the public subnet (SSH access restricted to your IP)
- 6 Docker hosts in the private subnet (accessible only through the bastion)
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

Copy that AMI ID — you will need it in the next step.

---

## Step 3 — Configure terraform.tfvars

Open `terraform/terraform.tfvars` and set the following values:

```hcl
ami_id         = "ami-xxxxxxxxxxxxxxxxx"   # AMI ID from the Packer build
my_ip          = "x.x.x.x"                # Your public IP: curl -s ifconfig.me
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

## Step 5 — Connect to a private instance

After `terraform apply` completes, get the bastion IP and private instance IPs:

```bash
terraform output bastion_public_ip
terraform output private_instance_ips
```

Add your SSH key to the agent, then jump through the bastion to any private instance:

```bash
ssh-add ~/.ssh/id_ed25519
ssh -A -J ec2-user@<bastion_public_ip> ec2-user@<private_instance_ip>
```

For example, to connect to docker-host-1:

```bash
ssh -A -J ec2-user@16.144.154.142 ec2-user@10.0.2.187
```

The `-A` flag forwards your SSH agent through the bastion so it can authenticate to the private instance. Docker is pre-installed and ready:

```bash
docker run hello-world
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
├── install-dependencies.sh  # Provisioning script run by Packer inside the AMI
└── terraform/
    ├── main.tf              # VPC module, security groups, 6 private EC2 instances
    ├── bastion.tf           # Bastion host in the public subnet
    ├── variables.tf         # Input variable declarations
    ├── outputs.tf           # Bastion IP, private IPs, SSH command
    └── terraform.tfvars     # Variable values (ami_id, my_ip, public_key)
```
