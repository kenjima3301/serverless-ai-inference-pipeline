output "table_name" {
  description = "Name of DynamoDB table"
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "ARN of DynamoDB table (use to write policy to authorize for IAM Role)"
  value       = aws_dynamodb_table.this.arn
}

