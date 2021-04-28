provider "aws" {
  version = ">= 3.12.0"
  region  = var.aws_region
}

module "aws_dagster" {
  source = "../.."
  public_subnet = [
  "subnet-08da686d46e99872d",
  "subnet-0e5bb83f963f8df0f"
]
  resource_prefix = var.resource_prefix
  resource_suffix = var.resource_suffix
  dagster_config_bucket = var.dagster_config_bucket
  rds_password = "Test123456"
  rds_username = "psuser"
  vpc          = "vpc-0eafa6867cb3bdaa3"
  use_https    = true
  route53_zone_name = "aws-sandbox.dataroots.io"
}