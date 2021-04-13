resource "aws_s3_bucket" "b" {
  bucket = "dagster-first-bucket"
  acl    = "public"

  versioning {
    enabled = true
  }
}

