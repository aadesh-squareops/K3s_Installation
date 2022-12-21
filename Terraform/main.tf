locals {
  private_ip_master = module.k3sMaster_instance.private_ip
  MasterCount = 1
  WorkerCount = 1
}

resource "aws_security_group" "k3s-sg" {

  name   = "aadesh-k3s-sg"
  vpc_id = "vpc-015507e5299f6073c"
  
  dynamic "ingress" {
    for_each = var.k3s_inbound_ports
    content {
      from_port   = ingress.value.internal
      to_port     = ingress.value.external
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.cidrBlock]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aadesh-k3s-sg"
  }
}

module "k3sMaster_instance" {
  # count = local.MasterCount
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "aadesh-k3s-master"

  ami                    = "ami-0530ca8899fac469f"
  instance_type          = "t3a.medium"
  key_name               = "aadesh"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.k3s-sg.id]
  subnet_id              = "subnet-00614134196ed093d"
  user_data              = file("k3s_Master.sh")
  tags = {
    "kubernetes.io/cluster/k3s-aadesh" = "owned"
  }
}

module "k3sWorker_instance" {
  # count = local.WorkerCount
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "aadesh-k3s-worker"

  ami                    = "ami-0530ca8899fac469f"
  instance_type          = "t3a.medium"
  key_name               = "aadesh"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.k3s-sg.id]
  subnet_id              = "subnet-00614134196ed093d"
  user_data              = <<EOF
#!/bin/bash

apt-get update
apt-get upgrade -y

local_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
flannel_iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)')
provider_id="$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

CUR_HOSTNAME=$(cat /etc/hostname)
NEW_HOSTNAME=$instance_id

hostnamectl set-hostname $NEW_HOSTNAME
hostname $NEW_HOSTNAME

sudo sed -i "s/$CUR_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
sudo sed -i "s/$CUR_HOSTNAME/$NEW_HOSTNAME/g" /etc/hostname

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.23.9+k3s1 K3S_TOKEN=coIeS98V5UxzKYTLX0Uzzd4pkxfPSwBxiCUFtUm1sURd66mnZlT3uhk K3S_URL=https://${local.private_ip_master}:6443 sh -s - agent --node-ip $local_ip  --kubelet-arg="provider-id=aws:///$provider_id"
EOF

  tags = {
    "kubernetes.io/cluster/k3s-aadesh" = "owned"
  }
}