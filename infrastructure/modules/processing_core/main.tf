# Group 1
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.env}-ai-processor"
  retention_in_days = 3

  tags = {
    Environment = var.env
    Project     = "Serverless-AI"
  }
}

# Group 2
resource "aws_iam_role" "this" {
  name = "${var.env}-lambda-ai-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "this" {
  name = "test_policy"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject*",
        ]
        Effect   = "Allow"
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Action = [
          "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes",
        ]
        Effect   = "Allow"
        Resource = var.sqs_queue_arn
      },
      {
        Action = [
          "dynamodb:PutItem",
        ]
        Effect   = "Allow"
        Resource = var.dynamodb_table_arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_policy" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Group 3
resource "aws_lambda_function" "this" {
  function_name = "${var.env}-ai-processor"
  role          = aws_iam_role.this.arn
  package_type  = "Image"
  image_uri     = var.ecr_image_uri
  timeout       = 30
  memory_size   = 1024
  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }
  depends_on = [aws_cloudwatch_log_group.this]
}

# Group 4
resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.this.arn
  batch_size       = 1
}
