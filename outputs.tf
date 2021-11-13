output "sns_topic" {
  value       = local.enabled ? aws_sns_topic.this : null
  description = "SNS topic"
}

output "sns_topic_name" {
  value       = local.enabled ? local.sqs_queue_name : null
  description = "SNS topic name"
}

output "sns_topic_id" {
  value       = local.enabled ? aws_sns_topic.this[0].id : null
  description = "SNS topic ID"
}

output "sns_topic_arn" {
  value       = local.enabled ? aws_sns_topic.this[0].arn : null
  description = "SNS topic ARN"
}

output "sns_topic_owner" {
  value       = local.enabled ? aws_sns_topic.this[0].owner : null
  description = "SNS topic owner"
}

output "aws_sns_topic_subscriptions" {
  value       = local.enabled ? aws_sns_topic_subscription.this : null
  description = "SNS topic subscription"
}

output "sqs_queue_url" {
  description = "The URL for the created Amazon SQS queue."
  value       = var.sqs_dlq_enabled ? aws_sqs_queue.dead_letter_queue[0].url : null
}

output "sqs_queue_id" {
  description = "The ID for the created Amazon SQS queue. Same as the URL."
  value       = var.sqs_dlq_enabled ? aws_sqs_queue.dead_letter_queue[0].id : null
}

output "sqs_queue_name" {
  description = "The name for the created Amazon SQS queue."
  value       = var.sqs_dlq_enabled ? local.sqs_queue_name : null
}

output "sqs_queue_arn" {
  description = "The ARN of the SQS queue"
  value       = var.sqs_dlq_enabled ? aws_sqs_queue.dead_letter_queue[0].arn : null
}
