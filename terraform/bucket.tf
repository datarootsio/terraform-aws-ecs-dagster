resource "aws_s3_bucket" "b" {
  bucket = "sander-first-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }
}

