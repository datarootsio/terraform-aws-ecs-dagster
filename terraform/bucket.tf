resource "aws_s3_bucket" "b" {
  bucket = "sander-first-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }
}

data "aws_s3_bucket" "athena_results" {
  bucket = "athena-query-results-432226246114"
}

data "aws_s3_bucket" "tweet_streamer" {
  bucket = "rootsacademy-tweet-streamer"
}