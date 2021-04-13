resource "aws_s3_bucket" "b" {
  bucket = "dagster-first-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }
}

