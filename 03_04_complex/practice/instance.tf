//EC2 module
module "ec2_cluster" {
  source = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name = "frontend-linux"
  instance_count = 1

  ami = data.aws_ami.ami-linux.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.sg-frontend.id]
  subnet_id = module.vpc.public_subnets[1]

}