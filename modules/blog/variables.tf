variable "environment" {
  description = "Environment values."
  type = object({
    name     = string
    vpc_cidr = string
  })
  default = {
    name = "dev"
    vpc_cidr = "10.0.0.0/16"
  }
}

variable "autoscaling" {
  description = "Autoscaling values."
  type = object({
    instance_type = string
    min_size  = number
    max_size  = number
  })
  default = {
    instance_type = "t3.nano"
    min_size  = 1
    max_size  = 2
  }
}

variable "ami" {
  description = "AMI data values."
  type = object({
    name  = string
    owner = string 
  })
  default = {
    name  = "bitnami-tomcat-*-x86_64-hvm-ebs-nami"
    owner = "979382823631" # Bitnami
  }
}
