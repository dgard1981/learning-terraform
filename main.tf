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

data "aws_vpc" "default" {
  default = true
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

  vpc_id = data.aws_vpc.default.id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}
