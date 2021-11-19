provider "aws" {
  region = var.region
}

module "sns" {
  source = "../../"

  allowed_aws_services_for_sns_published = var.allowed_aws_services_for_sns_published

  sqs_dlq_enabled    = false
  fifo_topic         = false
  fifo_queue_enabled = false

  context = module.this.context
}
