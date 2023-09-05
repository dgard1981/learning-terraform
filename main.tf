data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "dev_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs            = data.aws_availability_zones.available.names
  public_subnets = [for x in range(length(data.aws_availability_zones.available.names)) : cidrsubnet("10.0.0.0/16", 8, x + 101)]

  enable_nat_gateway = true

  tags = {
    Environment = "dev"
  }
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  key_name = "terraform-course"

  vpc_security_group_ids = [module.blog_security_group.security_group_id]

  tags = {
    Name = "HelloWorld"
  }
}

module "blog_security_group" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "5.1.0"
  name        = "blog"
  description = "Allow HTTP and HTTPS from my IP in."

  vpc_id = module.dev_vpc.public_subnets[0]

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}
