output "s3_bucket_name" {
  description = "Name of Image storage"
  value       = aws_s3_bucket.this.bucket
}

output "s3_bucket_arn" {
  description = "ARN of Image storage"
  value       = aws_s3_bucket.this.arn
}

output "sqs_queue_arn" {
  description = "ARN of SQS queue"
  value       = aws_sqs_queue.this.arn
}
