provider "aws" {
  region     = "us-east-1"
  access_key = "AKIASE5J5ODG7GRDRF42"
  secret_key = ""
}

variable "subnet_prefix" {
  description = "cidr block for the subnet"
  type = "string"
  default = "10.0.66.0/24"
}

# 1. create vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
      Name = "production"
  }
}

# 2. create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

#   tags = {
#     Name = "main"
#   }
}

# 3. creat custom route table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod-route-table"
  }
}

# 4. create a subnet
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  #cidr_block = "10.0.1.0/24" (from terraform.tfvars)
  cidr_block = var.subnet_prefix
  availability_zone = "us-east-1a"

  tags = {
    Name = "prod-subnet"
  }
}

# 5. associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. create security group to allow port 22, 80, 443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTPS"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

    ingress {
    description      = "HTTP"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. create a network interface with an ip in the subet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# 8. assign an elastic ip to the network interface crete in step 7
resource "aws_eip" "web-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.gw
  ]
}

output "server_public_ip" {
  value = aws_eip.web-eip.public_ip
}

# 9. create ubuntu server and install and enable apache2
resource "aws_instance" "web-server" {
  ami           = "ami-09d56f8956ab235b3"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "tut"

  network_interface {
    network_interface_id = aws_network_interface.web-server-nic.id
    device_index         = 0
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install apache2 -y
    sudo systemctl start apache2
    sudo bash -c 'echo your first web server > /var/www/html/index.html'
    EOF

  tags = {
    Name = "ubuntu-web-server"
  }

}

output "server_private_ip" {
    value = aws_instance.web-server.private_ip
}