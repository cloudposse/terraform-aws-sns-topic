output "sns_topic" {
  value = module.sns.sns_topic
}

output "aws_sns_topic_subscription" {
  value = module.sns.aws_sns_topic_subscription
}
