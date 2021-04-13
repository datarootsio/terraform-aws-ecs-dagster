variable "s3-bucket" {
  type        = string
  description = "A first dagster bucket"
  default     = "dagster-first-bucket"
}

variable "file_path" {
  type = string
  default = "s3://dagster-first-bucket/"
}

variable "dagster-container-home" {
  type = string
  default = "/opt/dagster/app"
}

