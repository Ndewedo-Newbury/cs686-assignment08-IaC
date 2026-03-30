# cs686-assignment08-IaC

Beginner IaC project using Packer and Terraform to build and deploy an Amazon Linux 2023 EC2 instance with Docker on AWS.

**What gets deployed:**
- VPC with a public subnet, internet gateway, and route table
- Security group allowing SSH inbound
- EC2 instance running a custom AMI with Docker pre-installed

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
packer build packer.json
```

At the end of the build you will see output like:

```
--> amazon-ebs: AMIs were created:
us-west-2: ami-xxxxxxxxxxxxxxxxx
```

Copy that AMI ID — you will need it in the next step.

---

## Step 3 — Set the AMI ID

Open `terraform/terraform.tfvars` and replace the placeholder with your AMI ID:

```hcl
ami_id = "ami-xxxxxxxxxxxxxxxxx"
```

Optionally change `aws_region`, `instance_type`, or CIDR blocks to match your environment.

---

## Step 4 — Deploy with Terraform

```bash
cd terraform
terraform init    # downloads the AWS VPC module
terraform plan    # preview what will be created
terraform apply   # deploy (type 'yes' to confirm)
```

---

## Step 5 — Connect to the instance

After `terraform apply` completes, the outputs include an SSH command:

```
ssh_command = "ssh ec2-user@<public-ip>"
```

Run that command to connect. Docker is pre-installed and ready:

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
├── packer.json              # Packer build config — creates the Docker AMI
├── install-dependencies.sh  # Provisioning script run by Packer inside the AMI
└── terraform/
    ├── main.tf              # VPC module, security group, EC2 instance
    ├── variables.tf         # Input variable declarations
    ├── outputs.tf           # Public IP, instance ID, SSH command
    └── terraform.tfvars     # Variable values (set ami_id here after Packer build)
```
