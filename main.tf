terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.15.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "security-group-ports" {
  default = [22, 80, 443]
}

variable "instance-type" {
  default   = "t3.medium"
  sensitive = true
}

resource "aws_security_group" "ports" {
  name        = "ssh"
  description = "allow ssh"

  dynamic "ingress" {
    for_each = var.security-group-ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# allows instance to securley interact with other AWS services
resource "aws_iam_role" "ec2_role" {
  name = "terraform-ec2-role"
  assume_role_policy = jsonencode({
    # Version should be here
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "terraform-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_key_pair" "docker-key" {
  key_name   = "docker-key"
  public_key = file("docker-key.pem.pub")
}

resource "aws_instance" "tf-ec2" {
  ami                    = "ami-052064a798f08f0d3" # aws linux ami
  instance_type          = var.instance-type
  key_name               = "docker-key"
  vpc_security_group_ids = [aws_security_group.ports.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "Docker"
  }

  provisioner "local-exec" {
    command = "echo ssh -i docker-key.pem ec2-user@${aws_instance.tf-ec2.public_dns} > connect.sh"
  }
    # needed for remote / file exec provisioners
  connection {
    host = self.public_dns
    type = "ssh"
    user = "ec2-user"
    private_key = file ("docker-key.pem")
  }

  # copy file to remote
  provisioner "file" {
    source = "./ec2_bashrc.txt"
    destination = "/home/ec2-user/custom_prompt.txt"
  }

  # copy file to remote
  provisioner "file" {
    source = "./get_k8s_learning.sh"
    destination = "/home/ec2-user/get_k8s_learning.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "cat /home/ec2-user/custom_prompt.txt >> /home/ec2-user/.bashrc"
    ]
  }

  # terraform installs this while instance created
  user_data = <<-EOF
                #!/bin/bash
                dnf update -y
                # install docker
                dnf install docker -y
                systemctl start docker
                systemctl enable docker
                usermod -a -G docker ec2-user
                # install docker-compose
                curl -L "https://github.com/docker/compose/releases/download/v2.40.0/docker-compose-linux-x86_64" \
                -o /usr/local/bin/docker-compose
                chmod +x /usr/local/bin/docker-compose
                # install kubectl and minikube
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
                sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
                echo 'alias kc="kubectl"' >> /home/ec2-user/.bashrc
                sudo -u ec2-user minikube start
                EOF
}

output "ec2-public-ip" {
  value = aws_instance.tf-ec2.public_ip
}

output "ec2-ssh" {
  value = "ssh -i docker-key.pem ec2-user@${aws_instance.tf-ec2.public_dns}"
}
