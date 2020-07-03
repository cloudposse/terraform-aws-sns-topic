provider "aws" {
  region = var.region
}

module "sns" {
  source        = "../../"
  namespace     = var.namespace
  name          = var.name
  stage         = var.stage
}
