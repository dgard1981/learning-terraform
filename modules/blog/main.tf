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
    for az in data.aws_availability_zones.available.names:
      az => regex("[a-z]$", az)
  })

  available_zone_cidr_blocks = tomap({
    for az, n in local.available_zone_letters:
      az => cidrsubnet(var.environment.vpc_cidr, 8, local.az_network_numbers[n])
  })
}

data "aws_ami" "tomcat" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami.owner]
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment.name
  cidr = var.environment.vpc_cidr

  azs                     = keys(local.available_zone_cidr_blocks)
  public_subnets          = values(local.available_zone_cidr_blocks)
  map_public_ip_on_launch = true

  tags = {
    Environment = var.environment.name
  }
}

module "blog_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${var.environment.name}-blog"
  description = "Allow HTTP and HTTPS from my IP in."

  vpc_id = module.blog_vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

module "blog_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.10.0"

  name          = "${var.environment.name}-blog"
  image_id      = data.aws_ami.blog.id
  
  instance_type = var.autoscaling.instance_type
  min_size = var.autoscaling.min_size
  max_size = var.autoscaling.max_size
  
  vpc_zone_identifier = module.blog_vpc.public_subnets
  security_groups     = [module.blog_security_group.security_group_id]
  target_group_arns   = module.blog_alb.target_group_arns
}

module "blog_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "${var.environment.name}-blog"

  load_balancer_type = "application"

  vpc_id             = module.blog_vpc.vpc_id
  subnets            = module.blog_vpc.public_subnets
  security_groups    = [module.blog_security_group.security_group_id]

  target_groups = [
    {
      name_prefix      = "${var.environment.name}-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
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
    Environment = var.environment.name
  }
}
