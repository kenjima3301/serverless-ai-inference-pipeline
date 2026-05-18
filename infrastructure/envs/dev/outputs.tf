output "client_api_url" {
  description = "Link API Gateway for Client to upload/get result"
  value       = module.client_api.api_endpoint
}

output "dynamodb_table_name" {
  description = "DynamoDB table stores results"
  value       = module.my_database.table_name
}

output "s3_upload_bucket" {
  description = "S3 Bucket stores raw images"
  value       = module.upload_trigger.s3_bucket_name
}

output "ecr_repository_url" {
  value = module.container_registry.repository_url
}
output "aws_console_dynamodb_link" {
  value = "https://ap-southeast-1.console.aws.amazon.com/dynamodbv2/home?region=ap-southeast-1#item-explorer?table=${module.my_database.table_name}"
}
