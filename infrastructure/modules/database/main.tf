resource "aws_dynamodb_table" "this" {
  name         = "${var.env}-${var.table_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "request_id"
  attribute {
    name = "request_id"
    type = "S"
  }
  tags = merge(
    {
      Environment = var.env
      Project     = "Serverless-AI"
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}
