data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_network_numbers = tomap({
    a = 101
    b = 102
    c = 103
    d = 104
    e = 105
    f = 106
  })

  available_zone_letters = tomap({
    for az in data.aws_availability_zones.available.names :
    az => regex("[a-z]$", az) # take only the final letter
  })

  available_zone_cidr_blocks = tomap({
    for az, k in local.available_zone_letters :
    az => cidrsubnet("10.0.0.0/16", 8, local.az_network_numbers[k])
  })
}

module "dev_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs                     = keys(local.available_zone_cidr_blocks)
  public_subnets          = values(local.available_zone_cidr_blocks)
  map_public_ip_on_launch = true

  tags = {
    Environment = "dev"
  }
}

module "blog_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "blog"
  description = "Allow HTTP and HTTPS from my IP in."

  vpc_id = module.dev_vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

data "aws_ami" "blog" {
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

resource "aws_instance" "blog" {
  ami           = data.aws_ami.blog.id
  instance_type = var.instance_type

  subnet_id = module.dev_vpc.public_subnets[0]
  vpc_security_group_ids      = [module.blog_security_group.security_group_id]

  tags = {
    Name = "HelloWorld"
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "blog-alb"

  load_balancer_type = "application"

  vpc_id             = module.dev_vpc.vpc_id
  subnets            = module.dev_vpc.public_subnets
  security_groups    = [module.blog_security_group.security_group_id]

  target_groups = [
    {
      name_prefix      = "blog-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = {
        my_target = {
          target_id = aws_instance.blog.id
          port = 80
        }
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "dev"
  }
}