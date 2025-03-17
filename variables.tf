variable "subscribers" {
  type = map(object({
    protocol = string
    # The protocol to use. The possible values for this are: sqs, sms, lambda, application. (http or https are partially supported, see below) (email is an option but is unsupported, see below).
    endpoint = string
    # The endpoint to send data to, the contents will vary with the protocol. (see below for more information)
    endpoint_auto_confirms = optional(bool, false)
    # Boolean indicating whether the end point is capable of auto confirming subscription e.g., PagerDuty (default is false)
    filter_policy = optional(string, null)
    # The filter policy JSON that is assigned to the subscription. For more information, see Amazon SNS Filter Policies.
    filter_policy_scope = optional(string, null)
    # The filter policy scope that is assigned to the subscription. Whether the `filter_policy` applies to `MessageAttributes` or `MessageBody`. Default is null.
    raw_message_delivery = optional(bool, false)
    # Boolean indicating whether or not to enable raw message delivery (the original message is directly passed, not wrapped in JSON with the original message in the message property) (default is false)
  }))
  description = "Required configuration for subscibres to SNS topic."
  default     = {}
}

variable "allowed_aws_services_for_sns_published" {
  type        = list(string)
  description = "AWS services that will have permission to publish to SNS topic. Used when no external JSON policy is used"
  default     = []
}

variable "kms_master_key_id" {
  type        = string
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK."
  default     = "alias/aws/sns"
}

variable "encryption_enabled" {
  type        = bool
  description = "Whether or not to use encryption for SNS Topic. If set to `true` and no custom value for KMS key (kms_master_key_id) is provided, it uses the default `alias/aws/sns` KMS key."
  default     = true
}

variable "sqs_queue_kms_master_key_id" {
  type        = string
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SQS Queue or a custom CMK"
  default     = "alias/aws/sqs"
}

variable "sqs_queue_kms_data_key_reuse_period_seconds" {
  type        = number
  description = "The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again"
  default     = 300
}

variable "allowed_iam_arns_for_sns_publish" {
  type        = list(string)
  description = "IAM role/user ARNs that will have permission to publish to SNS topic. Used when no external json policy is used."
  default     = []
}

variable "sns_topic_policy_json" {
  type        = string
  description = "The fully-formed AWS policy as JSON"
  default     = ""
}

# Enabling sqs_dlq_enabled won't be effective.
# SNS subscription - redrive policy parameter is not yet avaialable in TF - waiting for PR https://github.com/terraform-providers/terraform-provider-aws/issues/10931
variable "sqs_dlq_enabled" {
  type        = bool
  description = "Enable delivery of failed notifications to SQS and monitor messages in queue."
  default     = false
}

variable "sqs_dlq_max_message_size" {
  type        = number
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 262144 bytes (256 KiB). The default for this attribute is 262144 (256 KiB)."
  default     = 262144
}

variable "sqs_dlq_message_retention_seconds" {
  type        = number
  description = "The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days)."
  default     = 1209600
}

variable "delivery_policy" {
  type        = string
  description = "The SNS delivery policy as JSON."
  default     = null
}

variable "fifo_topic" {
  type        = bool
  description = "Whether or not to create a FIFO (first-in-first-out) topic"
  default     = false
}

variable "fifo_queue_enabled" {
  type        = bool
  description = "Whether or not to create a FIFO (first-in-first-out) queue"
  default     = false
}

variable "content_based_deduplication" {
  type        = bool
  description = "Enable content-based deduplication for FIFO topics"
  default     = false
}

variable "redrive_policy" {
  type        = string
  description = "The SNS redrive policy as JSON. This overrides the `deadLetterTargetArn` (supplied by `var.fifo_queue = true`) passed in by the module."
  default     = null
}

variable "delivery_status" {
  description = <<-EOT
    Enable Message delivery status for the various SNS subscription endpoints.
    The success_role_arn and failure_role_arn arguments are used to give Amazon SNS write
    access to use CloudWatch Logs on your behalf.
    The success_sample_rate argument is for specifying the sample rate percentage (0-100) of
    successfully delivered messages.
  EOT
  type = object({
    application = optional(object({
      success_role_arn    = string
      failure_role_arn    = string
      success_sample_rate = number
    }))
    firehose = optional(object({
      success_role_arn    = string
      failure_role_arn    = string
      success_sample_rate = number
    }))
    http = optional(object({
      success_role_arn    = string
      failure_role_arn    = string
      success_sample_rate = number
    }))
    lambda = optional(object({
      success_role_arn    = string
      failure_role_arn    = string
      success_sample_rate = number
    }))
    sqs = optional(object({
      success_role_arn    = string
      failure_role_arn    = string
      success_sample_rate = number
    }))
  })
  default = {}
}
