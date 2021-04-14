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
