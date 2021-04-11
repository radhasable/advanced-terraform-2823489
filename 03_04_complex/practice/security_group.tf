//SECURITY GROUP

resource "aws_security_group" "sg-frontend" {
  name = "sg-frontend"
  vpc_id = module.vpc.vpc_id

  ingress = [ {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 80
    protocol = "tcp"
     to_port = 80
  },
  {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 22
    protocol = "tcp"
     to_port = 22
  },
  {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 443
    protocol = "tcp"
     to_port = 443
  } ]

  egress = [ {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    protocol = "-1"
    to_port = 0
  } ]
  
}