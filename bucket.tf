resource "aws_s3_bucket" "repository_bucket" {
  bucket = var.dagster_config_bucket
  acl    = "private"

  versioning {
    enabled = true
  }
}

# Upload an object
resource "aws_s3_bucket_object" "workspace" {
  bucket = aws_s3_bucket.repository_bucket.id

  key = "config/${var.workspace_file}"

  acl = "private"

  source = "files/${var.workspace_file}"

  etag = filemd5("files/${var.workspace_file}")

}

// Upload dagster yaml
resource "aws_s3_bucket_object" "dagster" {
  bucket = aws_s3_bucket.repository_bucket.id

  key = "config/${var.dagster_file}"

  acl = "private" # or can be "public-read"

  source = "files/${var.dagster_file}"

  etag = filemd5("files/${var.dagster_file}")

}

resource "aws_s3_bucket_object" "repo" {
  bucket = aws_s3_bucket.repository_bucket.id

  for_each = fileset("files/tests/simple_dagster/", "*")

  key = "pipelines/${each.value}"

  acl = "private" # or can be "public-read"

  source = "files/tests/simple_dagster/${each.value}"

  etag = filemd5("files/tests/simple_dagster/${each.value}")

}
