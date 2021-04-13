resource "aws_s3_bucket" "b" {
  bucket = "dagster-first-bucket"
  acl    = "public-read-write"

  versioning {
    enabled = true
  }
}

