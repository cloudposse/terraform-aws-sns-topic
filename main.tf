data "aws_caller_identity" "current" {}

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
  for_each = var.subscribers

  topic_arn              = aws_sns_topic.this.arn
  protocol               = var.subscribers[each.key].protocol
  endpoint               = var.subscribers[each.key].endpoint
  endpoint_auto_confirms = var.subscribers[each.key].endpoint_auto_confirms
//  delivery_policy  = var.subscribers[each.key].delivery_policy
  # delivery_policy - (Optional) JSON String with the delivery policy (retries, backoff, etc.) that will be used in the subscription - this only applies to HTTP/S subscriptions. Refer to the SNS docs for more details.
}

resource "aws_sns_topic_policy" "this" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.aws_sns_topic_policy.json
}

data "aws_iam_policy_document" "aws_sns_topic_policy" {
  policy_id = "SNSTopicsPub"
  statement {
    effect = "Allow"
    actions = ["sns:Publish"]
    resources = [aws_sns_topic.this.arn]

    principals {
      type = "Service"
      identifiers = var.allowed_aws_services_for_sns_published
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:Referer"
      values = [data.aws_caller_identity.current.account_id]
    }
  }
}


# TODO Dead Letter SQS
## Create SQS
## Modify redelivery policy for SNS
## Monitor SQS queue for messages

## The following JSON object is a sample redrive policy, attached to an SNS subscription.
##{
##  "deadLetterTargetArn": "arn:aws:sqs:us-east-2:123456789012:MyDeadLetterQueue"
##}
