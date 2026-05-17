resource "aws_s3_bucket" "this" {
  bucket = "${var.bucket_name}-${var.env}-kltn2026"
  tags = {
    Name        = "Image storage"
    Environment = var.env
  }
}

resource "aws_sqs_queue" "this" {
  name                      = "${var.queue_name}-${var.env}-kltn2026"
  message_retention_seconds = 345600
}

data "aws_iam_policy_document" "s3_to_sqs" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.this.arn]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.this.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.id
  policy    = data.aws_iam_policy_document.s3_to_sqs.json
}

resource "aws_s3_bucket_notification" "this" {
  bucket = aws_s3_bucket.this.id
  queue {
    queue_arn     = aws_sqs_queue.this.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".jpg"
  }
  depends_on = [aws_sqs_queue_policy.this]
}
