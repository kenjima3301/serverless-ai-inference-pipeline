resource "aws_ecr_repository" "this" {
  name                 = "${var.env}-${var.repo_name}"
  force_delete         = true
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
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
