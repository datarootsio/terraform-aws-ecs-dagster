variable "dagster_config_bucket" {
  type        = string
  description = "Dagster bucket containing the config files."
  default     = "dagster-bucket"
}

variable "dagster-container-home" {
  type    = string
  default = "/opt"
}

variable "resource_prefix" {
  type        = string
  default     = "ps"
  description = "The prefix of the resource to be created"
}

variable "resource_suffix" {
  type        = string
  default     = "sp"
  description = "The suffix of the resource to be created"
}

variable "aws_region" {
  type        = string
  default     = "eu-west-1"
  description = "The region of the aws account"
}

variable "tags" {
  type        = map(string)
  default     = { Name = "Terraform-aws-dagster" }
  description = "Tags to add to the created resources."
}

variable "workspace_file" {
  type        = string
  default     = "workspace.yaml"
  description = "The config file needed to run dagit."
}

variable "dagster_file" {
  type        = string
  default     = "dagster.yaml"
  description = "The config file needed to use database and daemon with dagit."
}

variable "sync_script_file" {
  type        = string
  default     = "sync_script.sh"
  description = "Script used to sync pipelines to Dagster."
}

variable "repository" {
  type        = string
  default     = ""
  description = "where the repos are."
}

variable "private_subnet" {
  type        = string
  default     = ""
  description = "The private subnet."
}

variable "public_subnet" {
  type        = list(string)
  default     = ["subnet-08da686d46e99872d", "subnet-0e5bb83f963f8df0f"]
  description = "The public subnet."
}

variable "vpc" {
  type        = string
  default     = "vpc-0eafa6867cb3bdaa3"
  description = "The id of the virtual private cloud."
}

variable "rds_instance_class" {
  type        = string
  default     = "db.t2.micro"
  description = "The type of instance class for the RDS."
}

variable "rds_username" {
  type        = string
  default     = "psuser"
  description = "The username to access the RDS instance."
}

variable "rds_password" {
  type        = string
  default     = "Test123456"
  description = "The password to access the RDS instance."
}

variable "aws_availability_zone" {
  type        = string
  default     = "eu-west-1a"
  description = "The availability zone of the resource."
}

variable "rds_deletion_protection" {
  type        = bool
  default     = false
  description = ""
}
