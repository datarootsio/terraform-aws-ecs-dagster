resource "aws_s3_bucket" "b" {
  bucket = var.dagster_config_bucket
  acl    = "private"

  versioning {
    enabled = true
  }
}

# Upload an object
resource "aws_s3_bucket_object" "workspace" {
  bucket = aws_s3_bucket.b.id

  key = var.workspace_file

  acl = "private" # or can be "public-read"

  source = "files/${var.workspace_file}"

  etag = filemd5("files/${var.workspace_file}")

}

resource "aws_s3_bucket_object" "repo" {
  bucket = aws_s3_bucket.b.id

  for_each = fileset("files/tests/simple_dagster/", "*")

  key = each.value

  acl = "private" # or can be "public-read"

  source = "files/tests/simple_dagster/${each.value}"

  etag = filemd5("files/tests/simple_dagster/${each.value}")

}
