resource "aws_key_pair" "bastion-key" {
  key_name   = "bastion-key"
  public_key = var.public_key
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Allow SSH from my IP only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.resource_tags
}

resource "aws_instance" "bastion" {
  ami                         = var.bastion_ami_id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = aws_key_pair.bastion-key.key_name
  associate_public_ip_address = true

  tags = merge(var.resource_tags, {
    Name = "${var.project_name}-bastion"
  })
}
