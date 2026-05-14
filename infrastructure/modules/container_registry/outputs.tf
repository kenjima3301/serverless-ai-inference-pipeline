output "repository_url" {
  description = "URL of ECR Repository"
  value       = aws_ecr_repository.this.repository_url
}
