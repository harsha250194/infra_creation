data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "current" {
  id = var.vpc_id == "new" ? aws_vpc.one_kube_new_vpc[0].id : var.vpc_id
  depends_on = [aws_vpc.one_kube_new_vpc]
}

data "aws_subnet_ids" "public" {
  vpc_id = var.vpc_id == "new" ? aws_vpc.one_kube_new_vpc[0].id : var.vpc_id
  tags = {
    "tmna:subnet:type" = "public"
  }
  depends_on = [aws_vpc.one_kube_new_vpc, aws_subnet.eks_one_kube_new_public_subnets]
}

data "aws_subnet_ids" "private" {
  vpc_id = var.vpc_id == "new" ? aws_vpc.one_kube_new_vpc[0].id : var.vpc_id
  tags = {
    "tmna:subnet:type" = "private"
  }
  depends_on = [aws_vpc.one_kube_new_vpc, aws_subnet.eks_one_kube_new_private_subnets]
}

locals {
//  public_subnet_ids = slice(sort(data.aws_subnet_ids.public.ids), 0, var.subnet_count)
//  private_subnet_ids = slice(sort(data.aws_subnet_ids.private.ids), 0, var.subnet_count)
  public_subnet_ids = tolist(sort(data.aws_subnet_ids.public.ids))
  private_subnet_ids = tolist(sort(data.aws_subnet_ids.private.ids))
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

// Configure the EC2 instance in a public subnet
resource "aws_instance" "ec2_public" {
  ami                         = data.aws_ami.amazon-linux-2.id
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = var.vpc.public_subnets[0]
  vpc_security_group_ids      = [var.sg_pub_id]

  tags = {
    "Name" = "${var.namespace}-EC2-PUBLIC"
  }

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
    inline = ["chmod 400 ~/${var.key_name}.pem"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.key_name}.pem")
      host        = self.public_ip
    }

  }

}

// Configure the EC2 instance in a private subnet
resource "aws_instance" "ec2_private" {
  ami                         = data.aws_ami.amazon-linux-2.id
  associate_public_ip_address = false
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = var.vpc.private_subnets[1]
  vpc_security_group_ids      = [var.sg_priv_id]

  tags = {
    "Name" = "${var.namespace}-EC2-PRIVATE"
  }

}