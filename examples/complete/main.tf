provider "aws" {
  region = var.region
}

module "sns" {
  source = "../../"

  context                                = module.this.context
  allowed_aws_services_for_sns_published = var.allowed_aws_services_for_sns_published
}
