terraform {
  backend "s3" {}
}


provider "aws" {
  assume_role {
    role_arn = var.aws_assume_role_arn
  }
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.15.0"
  namespace  = var.namespace
  name       = var.name
  stage      = var.stage
  attributes = var.attributes
}

resource "aws_sns_topic" "this" {
  name         = module.label.id
  display_name = module.label.id
}

resource "aws_sns_topic_subscription" "this" {
  for_each = toset(var.subscribers)

  topic_arn              = aws_sns_topic.this.arn
  protocol               = lookup(each.value, "protocol", null)
  endpoint               = lookup(each.value, "endpoint", null)
  endpoint_auto_confirms = lookup(each.value, "endpoint_auto_confirms", null)
  # delivery_policy  = lookup(each.value, "delivery_policy", null)
  # delivery_policy - (Optional) JSON String with the delivery policy (retries, backoff, etc.) that will be used in the subscription - this only applies to HTTP/S subscriptions. Refer to the SNS docs for more details.
}

//module "sns_monitoring" {
//  source = "git::https://github.com/cloudposse/terraform-aws-sns-cloudwatch-alarms.git?ref=master"
//  enabled = var.monitoring_enabled
//
//  sns_topic_name       = aws_sns_topic.this.name
//  sns_topic_alarms_arn = var.sns_topic_alarms_arn
//}

# TODO Dead Letter SQS
## Create SQS
## Modify redelivery policy for SNS
## Monitor SQS queue for messages

## The following JSON object is a sample redrive policy, attached to an SNS subscription.
##{
##  "deadLetterTargetArn": "arn:aws:sqs:us-east-2:123456789012:MyDeadLetterQueue"
##}
