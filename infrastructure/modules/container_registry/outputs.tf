output "repository_url" {
  description = "URL of ECR Repository"
  value       = aws_ecr_repository.ai_model_repo.repository_url
}
