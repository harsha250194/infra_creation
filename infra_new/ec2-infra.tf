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


// Configure the EC2 instance in a public subnet
resource "aws_instance" "ec2_public" {
  ami                         = data.aws_ami.amazon-linux-2.id
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = local.public_subnet_ids                #var.vpc.public_subnets[0]
  vpc_security_group_ids      = module.naming.ec2_sg

  tags = merge(
  {
    Name = module.naming.ec2_name,
    "tmna:terraform:script" = "ec2-infra.tf"
  }, module.naming.tags)

  # Copies the ssh key file to home dir
  provisioner "file" {
    source      = "./${var.key_name}.pem"
    destination = "/home/${var.key_name}.pem"

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