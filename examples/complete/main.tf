provider "aws" {
  region = var.region
}

locals {
  sqs_queues = ["foo", "bar"]
}

resource "aws_sqs_queue" "default" {
  for_each = toset(local.sqs_queues)

  name       = "${module.this.id}-${each.value}.fifo"
  fifo_queue = true
}

module "sns" {
  source = "../../"

  allowed_aws_services_for_sns_published = var.allowed_aws_services_for_sns_published

  subscribers = {
    for sqs in local.sqs_queues :
    sqs => {
      protocol               = "sqs"
      endpoint               = aws_sqs_queue.default[sqs].arn
      raw_message_delivery   = true
      endpoint_auto_confirms = false
    }
  }

  sqs_dlq_enabled    = true
  fifo_topic         = true
  fifo_queue_enabled = true

  context = module.this.context
}
