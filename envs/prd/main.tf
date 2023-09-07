module "blog" {
    source      = "../../modules/blog"
    environment = {
        name     = "prd"
        vpc_cidr = "10.2.0.0/16"
    }
}
