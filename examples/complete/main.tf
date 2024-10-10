provider "aws" {
  region = var.region
}

module "sns" {
  source = "../../"

  allowed_aws_services_for_sns_published = var.allowed_aws_services_for_sns_published

  sqs_dlq_enabled    = true
  fifo_topic         = true
  fifo_queue_enabled = true

  context = module.this.context
}

resource "aws_sqs_queue" "sqs" {
  name = "test-sqs"
  fifo_queue = false
}

module "sns_with_subscriber" {
  source = "../../"

  allowed_aws_services_for_sns_published = var.allowed_aws_services_for_sns_published

  subscribers = {
    "sqs" = {
      protocol = "sqs"
      endpoint = aws_sqs_queue.sqs.arn
      raw_message_delivery = true
    }
  }
  context = module.this.context
  attributes = ["sqs", "subscriber"]
}
