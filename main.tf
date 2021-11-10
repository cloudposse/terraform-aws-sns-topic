data "aws_caller_identity" "current" {}

locals {
  enabled = module.this.enabled

  kms_key_id = local.enabled && var.encryption_enabled && var.kms_master_key_id != "" ? var.kms_master_key_id : ""
}

resource "aws_sns_topic" "this" {
  count = local.enabled ? 1 : 0

  name                        = module.this.id
  display_name                = replace(module.this.id, ".", "-") # dots are illegal in display names and for .fifo topics required as part of the name (AWS SNS by design)
  kms_master_key_id           = local.kms_key_id
  delivery_policy             = var.delivery_policy
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.content_based_deduplication

  tags = module.this.tags
}

resource "aws_sns_topic_subscription" "this" {
  for_each = local.enabled ? var.subscribers : {}

  topic_arn              = join("", aws_sns_topic.this.*.arn)
  protocol               = var.subscribers[each.key].protocol
  endpoint               = var.subscribers[each.key].endpoint
  endpoint_auto_confirms = var.subscribers[each.key].endpoint_auto_confirms
  raw_message_delivery   = var.subscribers[each.key].raw_message_delivery
  # TODO enable when PR gets merged https://github.com/terraform-providers/terraform-provider-aws/issues/10931
  # redrive_policy        = length(aws_sqs_queue.dead_letter_queue.*) > 0 ? "{\"deadLetterTargetArn\": \"${join("", aws_sqs_queue.dead_letter_queue.*.arn)}\"}" : null
}

resource "aws_sns_topic_policy" "this" {
  count = local.enabled ? 1 : 0

  arn    = join("", aws_sns_topic.this.*.arn)
  policy = length(var.sns_topic_policy_json) > 0 ? var.sns_topic_policy_json : join("", data.aws_iam_policy_document.aws_sns_topic_policy.*.json)
}

data "aws_iam_policy_document" "aws_sns_topic_policy" {
  count = local.enabled ? 1 : 0

  policy_id = "SNSTopicsPub"
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = aws_sns_topic.this.*.arn

    dynamic "principals" {
      for_each = length(var.allowed_aws_services_for_sns_published) > 0 ? ["_enable"] : []
      content {
        type        = "Service"
        identifiers = var.allowed_aws_services_for_sns_published
      }
    }

    # don't add the IAM ARNs unless specified
    dynamic "principals" {
      for_each = length(var.allowed_iam_arns_for_sns_publish) > 0 ? ["_enable"] : []
      content {
        type        = "AWS"
        identifiers = var.allowed_iam_arns_for_sns_publish
      }
    }
  }
}

module "sqs_queue_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  # Allow periods in sqs queue because FIFO queues require .fifo suffixed in the name
  regex_replace_chars = "/[^a-zA-Z0-9-.]/"

  context = module.this.context
}

resource "aws_sqs_queue" "dead_letter_queue" {
  count = local.enabled && var.sqs_dlq_enabled ? 1 : 0

  name                              = module.sqs_queue_label.id
  max_message_size                  = var.sqs_dlq_max_message_size
  message_retention_seconds         = var.sqs_dlq_message_retention_seconds
  kms_master_key_id                 = var.sqs_queue_kms_master_key_id
  kms_data_key_reuse_period_seconds = var.sqs_queue_kms_data_key_reuse_period_seconds

  tags = module.sqs_queue_label.tags
}

data "aws_iam_policy_document" "sqs-queue-policy" {
  count = local.enabled && var.sqs_dlq_enabled ? 1 : 0

  policy_id = "${join("", aws_sqs_queue.dead_letter_queue.*.arn)}/SNSDeadLetterQueue"

  statement {
    effect    = "Allow"
    actions   = ["SQS:SendMessage"]
    resources = [join("", aws_sqs_queue.dead_letter_queue.*.arn)]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = aws_sns_topic.this.*.arn
    }
  }
}
