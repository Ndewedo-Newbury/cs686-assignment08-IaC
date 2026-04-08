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

![alt text](image.png)

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

![alt text](image-1.png)

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

## Step 6 - Connect to Grafana via SSH

use the ssh command provided by the terraform output:

```bash
ssh -L 3000:10.0.2.119:3000 -L 9090:10.0.2.119:9090 -J ec2-user@16.146.71.67 ec2-user@10.0.2.119
```

Then in the remote terminal run 
```bash
cd /opt/monitoring && docker compose up -d
```

then connect to Grafana using url:  http://localhost:3000 
login: 
Username: admin 
Password:changeme

To setup Grafana connections, go to Connections → Data Sources and check if Prometheus is
  listed with a green checkmark. If not, add it manually:

  1. Connections → Data Sources → Add data source → Prometheus
  2. Set URL to http://prometheus:9090 (they're on the same Docker
  network)
  3. Click Save & Test — it should say "Successfully queried the
  Prometheus API"
  
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
├── image.png                # Screenshot: Packer AMI build output
├── image-1.png              # Screenshot: Terraform output (bastion IP, private IPs)
└── terraform/
    ├── main.tf              # VPC module, security groups, 6 private EC2 instances
    ├── bastion.tf           # Bastion host in the public subnet
    ├── monitoring.tf        # Monitoring host — Prometheus, Grafana, node_exporter
    ├── variables.tf         # Input variable declarations
    ├── outputs.tf           # Bastion IP, private IPs, monitoring IP, SSH commands
    └── terraform.tfvars     # Variable values (ami_id, my_ip, public_key)
```

Yes — the inventory file lives on the Ansible controller instance. The workflow is:                                                                   
                                                                                                                                                        
  1. Run terraform output on your local machine to get the private IPs                                                                                  
  2. SSH into the Ansible controller:                                                                                                                   
  ssh -J ec2-user@<bastion_ip> ec2-user@<ansible_controller_ip>                                                                                         
  3. Create the inventory file there:
  vi ~/inventory.ini
  4. Paste in the IPs and run your playbook:
  ansible-playbook -i ~/inventory.ini check_docker_version.yml
  
The hosts: field in the playbook maps to the group names in your inventory. Since you'd have [amazon_linux] and [ubuntu] groups in inventory.ini, you 
  set:                                                                                                                                                  
                                                                                                                                                        
  - name: Check Docker version on all hosts                                                                                                             
    hosts: all  # or "amazon_linux:ubuntu" or just "all"                                                                                                
                  
  Then run it with:

  ansible-playbook -i ~/inventory.ini check_docker_version.yml

  Ansible reads the inventory, resolves the IPs in each group, and SSHs into each one to run the tasks. The when: ansible_os_family == "RedHat" /
  "Debian" conditions in the playbook will automatically route the yum vs apt tasks to the right hosts.

  You'll also need to tell Ansible which SSH key to use — either pass it at runtime:

  ansible-playbook -i ~/inventory.ini check_docker_version.yml --private-key ~/.ssh/your_key.pem

  Or set it in an ansible.cfg next to the playbook:

  [defaults]
  private_key_file = ~/.ssh/your_key.pem
  remote_user = ec2-user

ansible-playbook -i ~/inventory.ini check_docker_version.yml

❯ what would the contents of the ansible.cfg look like?                                                                                                 
                                                        
● [defaults]                                                                                                                                            
  inventory = ~/inventory.ini                                                                                                                           
  remote_user = ec2-user                                                                                                                                
  private_key_file = ~/.ssh/your_key.pem                                                                                                                
  host_key_checking = False                                                                                                                             
                  
  - remote_user — ec2-user is the default for both Amazon Linux and Ubuntu AMIs on AWS
  - private_key_file — the .pem key pair you assigned to the instances in Terraform
  - host_key_checking = False — skips the SSH fingerprint prompt on first connection (common for ephemeral EC2s)