variable "env" {
  description = "Name of environment"
  type        = string
}

variable "ecr_image_uri" {
  description = "Name of Docker image that Lambda will use"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of SQS queue to create Trigger and grant access to read queue"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of S3 bucket"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of DynamoDB table"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of DynamoDB table"
}
