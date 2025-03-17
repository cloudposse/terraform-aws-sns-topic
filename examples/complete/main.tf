provider "aws" {
  region = var.region
}

module "sns" {
  source = "../../"

  allowed_aws_services_for_sns_published = var.allowed_aws_services_for_sns_published

  sqs_dlq_enabled    = true
  fifo_topic         = true
  fifo_queue_enabled = true

  delivery_status = {
    application = {
      failure_role_arn    = aws_iam_role.this.arn
      success_role_arn    = aws_iam_role.this.arn
      success_sample_rate = 100
    }
    firehose = {
      failure_role_arn    = aws_iam_role.this.arn
      success_role_arn    = aws_iam_role.this.arn
      success_sample_rate = 100
    }
    http = {
      failure_role_arn    = aws_iam_role.this.arn
      success_role_arn    = aws_iam_role.this.arn
      success_sample_rate = 100
    }
    lambda = {
      failure_role_arn    = aws_iam_role.this.arn
      success_role_arn    = aws_iam_role.this.arn
      success_sample_rate = 100
    }
    sqs = {
      failure_role_arn    = aws_iam_role.this.arn
      success_role_arn    = aws_iam_role.this.arn
      success_sample_rate = 100
    }
  }

  context = module.this.context
}

resource "aws_sqs_queue" "sqs" {
  name       = "test-sqs"
  fifo_queue = false
}

module "sns_with_subscriber" {
  source = "../../"

  allowed_aws_services_for_sns_published = var.allowed_aws_services_for_sns_published

  subscribers = {
    "sqs" = {
      protocol             = "sqs"
      endpoint             = aws_sqs_queue.sqs.arn
      raw_message_delivery = true
    }
  }
  context    = module.this.context
  attributes = ["sqs", "subscriber"]
}

resource "aws_iam_role" "this" {
  name = module.this.id_full

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "SnsAssume"
        Principal = {
          Service = "sns.amazonaws.com"
        }
      },
    ]
  })

  tags = module.this.tags_all
}

resource "aws_iam_role_policy" "this" {
  name = module.this.id_full
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutMetricFilter",
          "logs:PutRetentionPolicy",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
