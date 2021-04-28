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

variable "dagster_config_bucket" {
  type        = string
  default     = "dagster-config-bucket"
  description = "The bucket where the config and the pipeline files reside."
}