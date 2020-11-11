provider "aws" {
  region = var.region
}

module "sns" {
  source = "../../"

  context = module.this.context
}
