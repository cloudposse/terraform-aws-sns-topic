locals {
  enabled = module.this.enabled

  kms_key_id = local.enabled && var.encryption_enabled && var.kms_master_key_id != "" ? var.kms_master_key_id : ""

  sns_topic_name = var.fifo_topic ? "${module.this.id}.fifo" : module.this.id
  sqs_queue_name = var.fifo_queue_enabled ? "${module.this.id}.fifo" : module.this.id

  sqs_dlq_enabled = local.enabled && var.sqs_dlq_enabled

  sns_topic_policy_enabled = local.enabled && length(var.allowed_aws_services_for_sns_published) > 0 || length(var.allowed_iam_arns_for_sns_publish) > 0
}

resource "aws_sns_topic" "this" {
  count = local.enabled ? 1 : 0

  name                        = local.sns_topic_name
  display_name                = replace(module.this.id, ".", "-") # dots are illegal in display names and for .fifo topics required as part of the name (AWS SNS by design)
  kms_master_key_id           = local.kms_key_id
  delivery_policy             = var.delivery_policy
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.content_based_deduplication

  application_failure_feedback_role_arn    = try(var.delivery_status.application.failure_role_arn, null)
  application_success_feedback_role_arn    = try(var.delivery_status.application.success_role_arn, null)
  application_success_feedback_sample_rate = try(var.delivery_status.application.success_sample_rate, null)
  firehose_failure_feedback_role_arn       = try(var.delivery_status.firehose.failure_role_arn, null)
  firehose_success_feedback_role_arn       = try(var.delivery_status.firehose.success_role_arn, null)
  firehose_success_feedback_sample_rate    = try(var.delivery_status.firehose.success_sample_rate, null)
  http_failure_feedback_role_arn           = try(var.delivery_status.http.failure_role_arn, null)
  http_success_feedback_role_arn           = try(var.delivery_status.http.success_role_arn, null)
  http_success_feedback_sample_rate        = try(var.delivery_status.http.success_sample_rate, null)
  lambda_failure_feedback_role_arn         = try(var.delivery_status.lambda.failure_role_arn, null)
  lambda_success_feedback_role_arn         = try(var.delivery_status.lambda.success_role_arn, null)
  lambda_success_feedback_sample_rate      = try(var.delivery_status.lambda.success_sample_rate, null)
  sqs_failure_feedback_role_arn            = try(var.delivery_status.sqs.failure_role_arn, null)
  sqs_success_feedback_role_arn            = try(var.delivery_status.sqs.success_role_arn, null)
  sqs_success_feedback_sample_rate         = try(var.delivery_status.sqs.success_sample_rate, null)

  tags = merge(module.this.tags, {
    Name = local.sns_topic_name
  })
}

resource "aws_sns_topic_subscription" "this" {
  for_each = local.enabled ? var.subscribers : {}

  topic_arn              = join("", aws_sns_topic.this[*].arn)
  protocol               = var.subscribers[each.key].protocol
  endpoint               = var.subscribers[each.key].endpoint
  endpoint_auto_confirms = var.subscribers[each.key].endpoint_auto_confirms
  filter_policy          = var.subscribers[each.key].filter_policy
  filter_policy_scope    = var.subscribers[each.key].filter_policy_scope
  raw_message_delivery   = var.subscribers[each.key].raw_message_delivery
  redrive_policy = var.sqs_dlq_enabled ? coalesce(var.redrive_policy, jsonencode({
    deadLetterTargetArn = join("", aws_sqs_queue.dead_letter_queue[*].arn)
  })) : null
}

resource "aws_sns_topic_policy" "this" {
  count = local.sns_topic_policy_enabled ? 1 : 0

  arn    = join("", aws_sns_topic.this.*.arn)
  policy = length(var.sns_topic_policy_json) > 0 ? var.sns_topic_policy_json : join("", data.aws_iam_policy_document.aws_sns_topic_policy.*.json)
}

data "aws_iam_policy_document" "aws_sns_topic_policy" {
  count = local.sns_topic_policy_enabled ? 1 : 0

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

resource "aws_sqs_queue" "dead_letter_queue" {
  count = local.sqs_dlq_enabled ? 1 : 0

  name                              = local.sqs_queue_name
  fifo_queue                        = var.fifo_queue_enabled
  max_message_size                  = var.sqs_dlq_max_message_size
  message_retention_seconds         = var.sqs_dlq_message_retention_seconds
  kms_master_key_id                 = var.sqs_queue_kms_master_key_id
  kms_data_key_reuse_period_seconds = var.sqs_queue_kms_data_key_reuse_period_seconds

  tags = merge(module.this.tags, {
    Name = local.sqs_queue_name
  })
}

resource "aws_sqs_queue_policy" "default" {
  count = local.sqs_dlq_enabled ? 1 : 0

  queue_url = join("", aws_sqs_queue.dead_letter_queue.*.id)

  policy = join("", data.aws_iam_policy_document.sqs_queue_policy.*.json)
}

data "aws_iam_policy_document" "sqs_queue_policy" {
  count = local.sqs_dlq_enabled ? 1 : 0

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
