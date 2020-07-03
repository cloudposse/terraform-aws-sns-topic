## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.12.0 |
| aws | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| attributes | Additional attributes to distinguish this SNS topic | `list(string)` | `[]` | no |
| aws\_assume\_role\_arn | n/a | `string` | n/a | yes |
| monitoring\_enabled | Flag to enable CloudWatch monitoring of SNS topic. | `bool` | `false` | no |
| name | Name to distinguish this SNS topic | `string` | `"sns"` | no |
| namespace | Namespace (e.g. `cp` or `cloudposse`) | `string` | n/a | yes |
| sns\_topic\_alarms\_arn | ARN of SNS topic that will be subscribed to an alarm. | `string` | `null` | no |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | `string` | n/a | yes |
| subscribers | Required configuration for subscibres to SNS topic. | <pre>list(object({<br>    protocol = string<br>    # The protocol to use. The possible values for this are: sqs, sms, lambda, application. (http or https are partially supported, see below) (email is an option but is unsupported, see below).<br>    endpoint = string<br>    # The endpoint to send data to, the contents will vary with the protocol. (see below for more information)<br>    endpoint_auto_confirms = bool<br>    # Boolean indicating whether the end point is capable of auto confirming subscription e.g., PagerDuty (default is false)<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| aws\_sns\_topic\_subscription | n/a |
| sns\_topic | n/a |

