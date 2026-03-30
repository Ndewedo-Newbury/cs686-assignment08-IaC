output "private_instance_ids" {
  description = "Instance IDs of all 6 private docker hosts"
  value       = aws_instance.docker_host[*].id
}

output "private_instance_ips" {
  description = "Private IPs of all 6 docker hosts"
  value       = aws_instance.docker_host[*].private_ip
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

output "bastion_dns" {
  description = "DNS name of the bastion host"
  value       = module.bastion.bastion_host_dns
}

output "bastion_ssh_command" {
  description = "SSH command to reach a private instance via the bastion (replace INDEX with 0-5)"
  value       = "ssh -J ec2-user@${module.bastion.bastion_host_dns} ec2-user@${aws_instance.docker_host[0].private_ip}"
}
