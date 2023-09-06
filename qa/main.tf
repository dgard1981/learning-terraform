module "qa" {
    source      = "../modules/blog"
    environment = {
        name     = "qa"
        vpc_cidr = "10.1.0.0/16"
    }
}
