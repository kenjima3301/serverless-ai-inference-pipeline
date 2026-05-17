module "my_database" {
  source = "../../modules/database"
  env    = "dev"
}

module "container_registry" {
  source = "../../modules/container_registry"
  env    = "dev"
}

module "upload_trigger" {
  source = "../../modules/upload_trigger"
  env    = "dev"
}

# module "processing_core" {
#   source              = "../../modules/processing_core"
#   env                 = "dev"
#   s3_bucket_arn       = module.upload_trigger.s3_bucket_arn
#   sqs_queue_arn       = module.upload_trigger.sqs_queue_arn
#   dynamodb_table_arn  = module.my_database.table_arn
#   dynamodb_table_name = module.my_database.table_name
#   ecr_image_uri       = "${module.container_registry.repository_url}:latest"
# }
