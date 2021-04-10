variable "aws_access_key" {}  //here the value will be derived from the tfvars file
variable "aws_secret_key" {}

variable "region" {
  default = "ap-south-1"
}

variable "vpc_cidr" {
  default = "172.16.0.0/16"  
}

variable "subnet_cidr" {
  default = "172.16.0.0/24"
}

variable "environment_list" {
  type = list(string)
  default = ["DEV", "STG", "PROD"]
}

variable "environment_map" {
  type = map(string)
  default = {
    "DEV" = "DEV",
    "STG" = "STG",
    "PROD" = "PROD"
  }
}

variable "environment_instance_type" {
  type = map(string)
  default = {
    "DEV" = "t2.micro",
    "STG" = "t2.micro",
    "PROD" = "t2.micro"
  }
}

variable "environment_instance_settings" {
  type = map(object({instance_type=string, monitoring=bool}))
  default = {
    "DEV" = {
    instance_type = "t2.micro",
    monitoring = false
    },
    "STG" = {
    instance_type = "t2.micro",
    monitoring = false
    },
    "PROD" = {
    instance_type = "t2.micro",
    monitoring = false
    }
   }
}

variable "deploy_environment" {
  default = "DEV"
}


//////////PROVIDER/////////////
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

///////RESOURCES//////////

//VPC
resource "aws_vpc" "vpc1" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = "true"
}

//SUBNET
resource "aws_subnet" "subnet1" {
  cidr_block = var.subnet1_cidr
  vpc_id = aws_vpc.vpc1.vpc_id
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[1]
}

//INTERNET GATEWAY
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.vpc_id
}

//ROUTE TABLE
resource "aws_route_table" "route_table1" {
  vpc_id = aws_vpc.vpc1.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.gateway_id
  }
}

//ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "route_subnet1" {
  subnet_id = aws_subnet.subnet1.subnet_id
  route_table_id = aws_route_table.route_table1.route_table_id
}

//SECURITY GROUP
resource "aws_security_group" "sg-nodejs-instance" {
  name = "nodejs-sg"
  vpc_id  =aws_vpc.vpc1.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//INSTANCE

resource "aws_instance" "nodejs1" {
  ami = data.aws_ami.aws-linux.id
  instance_type = var.environment_instance_type[var.deploy_environment]
 // instance_type = var.environment_instance_settings["DEV"].instance_type

  subnet_id = aws_subnet.subnet1.subnet_id
  vpc_security_group_ids = [aws_security_group.nodejs_sg.id]
  monitoring = var.environment_instance_settings[var.deploy_environment].monitoring
  tags = {Environment = var.environment_list[0]}
}


//DATA

data "aws_availability_zones" "available" {}

data "aws_ami" "aws-linux" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name = "root-device-type"
    values = ["ebs"]
    }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}


//OUTPUT
output "instance_dns" {
  value = aws_instance.nodejs1.public_dns
}

output "private_dns" {
  value = aws_instance.nodejs1.private_dns
}