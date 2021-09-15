data "aws_subnet_ids" "public_ec2" {
  vpc_id = var.vpc_id == "new" ? aws_vpc.one_kube_new_vpc[0].id : var.vpc_id
  tags = {
    "tmna:subnet:type" = "public"
  }
  depends_on = [aws_vpc.one_kube_new_vpc, aws_subnet.eks_one_kube_new_public_subnets]
}


// Create aws_ami filter to pick up the ami available in your region
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = module.naming.ec2_sg
  description = "Cluster communication with gitlab worker nodes"
  vpc_id      = data.aws_vpc.current.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
  {
    Name = module.naming.ec2_sg,
    "tmna:terraform:script" = "ec2-infra.tf"
  }, module.naming.tags)
}

resource "aws_security_group_rule" "ec2_ingress_allow" {
  cidr_blocks       = [var.gitlab_runners_cidr]
  description       = "Allow Gitlab to communicate with the cluster API server"
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  security_group_id = aws_security_group.ec2_sg.id
  type              = "ingress"
}

resource "aws_security_group_rule" "ec2_ssh_allow" {
  cidr_blocks       = [var.gitlab_runners_cidr]
  description       = "Allow Gitlab to communicate with the cluster API server"
  from_port         = 22
  protocol          = "tcp"
  to_port           = 22
  security_group_id = aws_security_group.ec2_sg.id
  type              = "ingress"
}

// Configure the EC2 instance in a public subnet
resource "aws_instance" "ec2_public" {
  ami                         = data.aws_ami.amazon-linux-2.id
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = "subnet-0f1ee124fd7821bf7"     #"${aws_subnet.eks_one_kube_new_public_subnets[0].id}"                #var.vpc.public_subnets[0]
  vpc_security_group_ids      = flatten(["${aws_security_group.ec2_sg.id}"])

  tags = merge(
  {
    Name = module.naming.ec2_name,
    "tmna:terraform:script" = "ec2-infra.tf"
  }, module.naming.tags)

  # Copies the ssh key file to home dir
  provisioner "file" {
    source      = "./${var.key_name}.pem"
    destination = "/home/ec2-user/${var.key_name}.pem"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.key_name}.pem")
      host        = self.public_ip
    }
  }
  
  //chmod key 400 on EC2 instance
  provisioner "remote-exec" {
    inline = [
      "chmod 400 ~/${var.key_name}.pem",
      "export DD_AGENT_MAJOR_VERSION=7",
      "export DD_API_KEY=${var.ddapikey}",
      "export DD_SITE='datadoghq.com'",
      "curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh",
      "bash -c install_script.sh"
      ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.key_name}.pem")
      host        = self.public_ip
    }

  }

  provisioner "file" {
    source      = "../http_check/conf.yaml"
    destination = "/root/etc/datadog-agent/conf.d/http_check.d/conf.yaml"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.key_name}.pem")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl restart datadog-agent",
      "sudo datadog-agent status"
      ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.key_name}.pem")
      host        = self.public_ip
    }

  }

}

# // Configure the EC2 instance in a private subnet
# resource "aws_instance" "ec2_private" {
#   ami                         = data.aws_ami.amazon-linux-2.id
#   associate_public_ip_address = false
#   instance_type               = "t3.micro"
#   key_name                    = var.key_name
#   subnet_id                   = var.vpc.private_subnets[1]
#   vpc_security_group_ids      = [var.sg_priv_id]

#   tags = {
#     "Name" = "${var.namespace}-EC2-PRIVATE"
#   }

# }