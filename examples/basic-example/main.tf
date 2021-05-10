terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

module "aws-dagster" {
  source = "../.."

  public_subnet = ["subnet-12345", "subnet-67890"]
  vpc           = "vpc-123456"

  resource_prefix       = "myawesome"
  resource_suffix       = "test"
  dagster_config_bucket = "myawesome-bucket-test"

  use_https = false

  rds_username = "databaseuser"
  rds_password = "SecretPassword123"
}


## The DNS name of the ALB, this can used to access the Dagit webserver.
output "dagster_alb_dns" {
  value = module.aws-dagster.dagster_alb_dns
}


//output "dagster_dns_record" {
//  description = "The created DNS record (only if \"use_https\" = true). If https support is enabled, this can be used to access to Dagit webserver"
//  value       = module.aws-dagster.dagster_dns_record
//}
//
//output "dagster_task_iam_role" {
//  description = "The IAM role of the dagster task, use this to give dagster more permissions"
//  value       = module.aws-dagster.dagster_task_iam_role
//}
//
//output "dagster_connection_sg" {
//  description = "The security group with which you can connect other instance to dagster, for example AWS GLUE"
//  value       = module.aws-dagster.dagster_connection_sg
//}