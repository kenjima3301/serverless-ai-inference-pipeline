module "my_database" {
  source = "../../modules/database"
  env    = "dev"
}

module "container_registry" {
  source = "../../modules/container_registry"
  env    = "dev"
}
