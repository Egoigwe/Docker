provider "aws" {
  region  = "eu-west-2"
  profile = "default"
}

# Create an RSA key of size 4096 bits
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# creating private key
resource "local_file" "key" {
  content         = tls_private_key.key.private_key_pem
  filename        = "docker.pem"
  file_permission = 600
}
# creating an Ec2 key
resource "aws_key_pair" "key" {
  key_name   = "docker-key"
  public_key = tls_private_key.key.public_key_openssh
}
# creating Ec2 for docker Vault
resource "aws_instance" "docker" {
  ami                         = "ami-07d1e0a32156d0d21" // redhat
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.key.id
  vpc_security_group_ids      = [aws_security_group.docker-sg.id]
  associate_public_ip_address = true
  user_data                   = local.docker-script

  tags = {
    Name = "docker-server"
  }
}
# creating Ec2 for maven
resource "aws_instance" "maven" {
  ami                         = "ami-07d1e0a32156d0d21" // redhat
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.key.id
  vpc_security_group_ids      = [aws_security_group.maven-sg.id]
  associate_public_ip_address = true
  user_data                   = local.maven-script

  tags = {
    Name = "maven-server"
  }
}

# security group for docker
resource "aws_security_group" "docker-sg" {
  name        = "docker-sg"
  description = "Allow Inbound Traffic"

  ingress {
    description = "application port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "docker-sg"
  }
}
# security group for maven
resource "aws_security_group" "maven-sg" {
  name        = "maven-sg"
  description = "Allow Inbound Traffic"

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "maven-sg"
  }
}

output "docker-ip" {
  value = aws_instance.docker.public_ip
}

output "maven-ip" {
  value = aws_instance.maven.public_ip
}