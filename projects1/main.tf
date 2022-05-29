provider "aws" {
  region     = "us-east-1"
  access_key = "AKIASE5J5ODG7GRDRF42"
  secret_key = ""
}

resource "aws_instance" "my-first-server" {
  ami           = "ami-09d56f8956ab235b3"
  instance_type = "t2.micro"

  tags = {
    Name = "ubuntu"
  }

}

resource "aws_vpc" "first-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
      Name = "production"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.first-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "prod-subnet"
  }
}

resource "aws_vpc" "second-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
      Name = "production"
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id     = aws_vpc.second-vpc.id
  cidr_block = "10.1.1.0/24"

  tags = {
    Name = "dev-subnet"
  }
}


# 1. create vpc
# 2. create internet gateway
# 3. creat custom route table
# 4. create a subnet
# 5. associate subnet with route table
# 6. create security group to allow port 22, 80, 443
# 7. create a network interface with an ip in the subet that was created in step 4
# 8. assign an elastic ip to the network interface crete in step 7
# 9. create ubuntu server and install and enable apache2

