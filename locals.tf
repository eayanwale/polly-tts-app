locals {
  RUNNER = "clixx-tts"

  website_bucket_name = "stack-enoch-polly-website"
  mp3_bucket_name     = "stack-enoch-polly-mp3"
  dynamodb_table_name = "posts"
  sns_topic_name      = "new_posts"

  mime_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
  }
}
