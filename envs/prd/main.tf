module "blog" {
    source      = "../../modules/blog"
    environment = {
        name     = "prd"
        vpc_cidr = "10.1.0.0/16"
    }
}
