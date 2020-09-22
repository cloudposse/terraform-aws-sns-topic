variable "namespace" {
  type        = string
  description = "Namespace (e.g. `cp` or `cloudposse`)"
}

variable "stage" {
  type        = string
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
}

variable "name" {
  type        = string
  description = "Name to distinguish this SNS topic"
  default     = "sns"
}

variable "attributes" {
  type        = list(string)
  description = "Additional attributes to distinguish this SNS topic"
  default     = []
}

variable "subscribers" {
  type = map(object({
    protocol = string
    # The protocol to use. The possible values for this are: sqs, sms, lambda, application. (http or https are partially supported, see below) (email is an option but is unsupported, see below).
    endpoint = string
    # The endpoint to send data to, the contents will vary with the protocol. (see below for more information)
    endpoint_auto_confirms = bool
    # Boolean indicating whether the end point is capable of auto confirming subscription e.g., PagerDuty (default is false)
  }))
  description = "Required configuration for subscibres to SNS topic."
  default     = {}
}

variable "allowed_aws_services_for_sns_published" {
  type        = list(string)
  description = "AWS services that will have permission to publish to SNS topic. Used when no external json policy is used."
  default     = ["cloudwatch.amazonaws.com"]
}

variable "kms_master_key_id" {
  type        = string
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK"
  default     = null
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
