// Change the name of the bucket -> 1 t too much
variable "s3-bucket" {
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

