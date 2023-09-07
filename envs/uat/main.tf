module "blog" {
    source      = "../../modules/blog"
    environment = {
        name     = "uat"
        vpc_cidr = "10.1.0.0/16"
    }
}
