#####variables
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "ssh_key_name" {}
variable "private_key_path" {}
variable "region" {
  default = "ap-south-1"
}
variable "vpc_cidr" {
  default = "172.16.0.0/16"
}

variable "subnet1_cidr" {
  default = "172.16.0.0/24"
}

#####provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
}

#####resources
resource "aws_vpc" "vpc1" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = "true"
}

resource "aws_subnet" "subnet1" {
  cidr_block = var.subnet1_cidr
  vpc_id = aws_vpc.vpc1.id
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[1]
}

#Internet gateway
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id
  }

#Route table
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id
  route = [ {
    cidr_block = "0.0.0.0/0"   #this means any subnet within the vpc
    egress_only_gateway_id = "value"
    gateway_id = aws_internet_gateway.igw1.id
   } ]
}

resource "aws_route_table_association" "route-subnet1" {   #this is necessary to create the route between
  subnet_id = aws_subnet.subnet1.id                        #the route table and the subnet
  route_table_id = aws_route_table.rt1.id
}

#####security group
resource "aws_security_group" "sg-nodejs-instance" {
  name = "nodejs-sg"
  vpc_id = aws_vpc.vpc1.id
  ingress   {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 80
    protocol = "tcp"
    to_port = 80
  } 

  ingress   {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 443
    protocol = "tcp"
    to_port = 443
  }
  ingress   {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 443
    protocol = "tcp"
    to_port = 443
  }
  egress   {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    protocol = "-1"
    to_port = 0
  }
  
}

#####Instance
resource "aws_instance" "nodejs1" {
  ami = data.aws_ami.aws-linux.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet1.id
  vpc_security_group_ids = [ aws_security_group.sg-nodejs-instance.id ]
  key_name = var.ssh_key_name

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_path)
  }
}


####data
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "aws-linux" {
  most_recent = true
  owners = [ "amazon" ]
  filter {
    name = "name"
    values = "amzn-ami-hvm*"
  }

  filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }

  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
}

###output
output "instance-dns" {
  value = aws_instance.nodejs1.public_dns
}



