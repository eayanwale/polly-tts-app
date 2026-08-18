locals {
  RUNNER = "clixx-tts"

  website_bucket_name = "stack-enoch-polly-website"
  mp3_bucket_name     = "stack-enoch-polly-mp3"
  dynamodb_table_name = "posts"
  sns_topic_name      = "new_posts"
  my_domain           = "clixx.example.com"
  s3_origin_id        = "myS3Origin"
}
