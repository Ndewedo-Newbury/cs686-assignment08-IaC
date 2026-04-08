output "ubuntu_instance_ids" {
  description = "Instance IDs of the 3 Ubuntu hosts"
  value       = aws_instance.ubuntu[*].id
}

output "ubuntu_instance_ips" {
  description = "Private IPs of the 3 Ubuntu hosts"
  value       = aws_instance.ubuntu[*].private_ip
}

output "amazon_linux_instance_ids" {
  description = "Instance IDs of the 3 Amazon Linux hosts"
  value       = aws_instance.amazon_linux[*].id
}

output "amazon_linux_instance_ips" {
  description = "Private IPs of the 3 Amazon Linux hosts"
  value       = aws_instance.amazon_linux[*].private_ip
}

output "ansible_controller_private_ip" {
  description = "Private IP of the Ansible Controller"
  value       = aws_instance.ansible_controller.private_ip
}

output "ansible_controller_ssh_command" {
  description = "SSH command to reach the Ansible Controller via the bastion"
  value       = "ssh -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.ansible_controller.private_ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.vpc.public_subnets[0]
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = module.vpc.private_subnets[0]
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to reach a private instance via the bastion"
  value       = "ssh -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.ubuntu[0].private_ip}"
}

