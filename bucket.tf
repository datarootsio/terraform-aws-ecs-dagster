resource "aws_s3_bucket" "repository_bucket" {
  bucket = var.dagster_config_bucket
  acl    = "private"

  versioning {
    enabled = true
  }
}

# Upload workspace config file
resource "aws_s3_bucket_object" "workspace" {
  bucket = aws_s3_bucket.repository_bucket.id

  key = "config/${var.workspace_file}"

  acl = "private"

  source = "${local.dagster_init_files}/${var.workspace_file}"

  etag = filemd5("${local.dagster_init_files}/${var.workspace_file}")

}

// Upload dagster config file
resource "aws_s3_bucket_object" "dagster" {
  bucket = aws_s3_bucket.repository_bucket.id

  key = "config/${var.dagster_file}"

  acl = "private" # or can be "public-read"

  source = "${local.dagster_init_files}/${var.dagster_file}"

  etag = filemd5("${local.dagster_init_files}/${var.dagster_file}")

}

// Upload the syncing pipeline
resource "aws_s3_bucket_object" "repo" {
  bucket = aws_s3_bucket.repository_bucket.id

  key = "pipelines/syncing_pipeline.py"

  acl = "private" # or can be "public-read"

  source = "${local.dagster_init_files}/syncing_pipeline.py"

  etag = filemd5("${local.dagster_init_files}/syncing_pipeline.py")

}
