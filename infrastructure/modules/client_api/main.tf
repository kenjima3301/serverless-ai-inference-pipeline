# Group 1: Data Archive
data "archive_file" "upload_zip" {
  type        = "zip"
  source_file = "../../../api_functions/upload_url.py"
  output_path = "${path.module}/upload.zip"
}

data "archive_file" "result_zip" {
  type        = "zip"
  source_file = "../../../api_functions/get_result.py"
  output_path = "${path.module}/result.zip"
}

# Group 2: Lambda
resource "aws_iam_role" "this" {
  name = "${var.env}-lambda-api-function-role"
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
  name = "${var.env}-lambda_api_policy"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "dynamodb:GetItem*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "upload" {
  filename         = data.archive_file.upload_zip.output_path
  source_code_hash = data.archive_file.upload_zip.output_base64sha256
  function_name    = "${var.env}-api-upload"
  role             = aws_iam_role.this.arn
  runtime          = "python3.10"
  handler          = "upload_url.lambda_handler"

  environment {
    variables = {
      ENVIRONMENT = "production"
      S3_BUCKET   = var.s3_bucket_name
    }
  }
}

resource "aws_lambda_function" "result" {
  filename         = data.archive_file.result_zip.output_path
  source_code_hash = data.archive_file.result_zip.output_base64sha256
  function_name    = "${var.env}-api-result"
  role             = aws_iam_role.this.arn
  runtime          = "python3.10"
  handler          = "get_result.lambda_handler"

  environment {
    variables = {
      ENVIRONMENT    = "production"
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }
}

# Group 3: HTTP API Gateway
resource "aws_apigatewayv2_api" "this" {
  name          = "${var.env}-client-gateway"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "apigw_upload" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.upload.invoke_arn
}

resource "aws_apigatewayv2_integration" "apigw_result" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.result.invoke_arn
}

resource "aws_apigatewayv2_route" "route_upload" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /upload-url"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_upload.id}"
}

resource "aws_apigatewayv2_route" "route_result" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /result"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_result.id}"
}

# Group 4: Authorize API Gateway to access Lambda
resource "aws_lambda_permission" "allow_access_upload" {
  statement_id  = "AllowAPIUploadInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*"
}

resource "aws_lambda_permission" "allow_access_result" {
  statement_id  = "AllowAPIResultInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.result.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*"
}
