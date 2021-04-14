// Change the name of the bucket -> 1 t too much
variable "bucket_name" {
  type        = string
  description = "A first dagster bucket"
  default     = "dagster-first-buckett"
}

// Change the name of the bucket -> 1 t too much
variable "file_path" {
  type    = string
  default = "s3://dagster-first-buckett/"
}

variable "dagster-container-home" {
  type    = string
  default = "/opt/dagster/app"
}

variable "resource_prefix" {
  type        = string
  default     = ""
  description = "The prefix of the resource to be created"
}

variable "resource_suffix" {
  type        = string
  default     = ""
  description = "The suffix of the resource to be created"
}

