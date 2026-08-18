### Website bucket ###

resource "aws_s3_bucket" "website_bucket" {
  bucket        = local.website_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.website_bucket,
    aws_s3_bucket_public_access_block.website_bucket,
  ]
}

resource "aws_s3_bucket_website_configuration" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.origin_bucket_policy.json

  depends_on = [aws_s3_bucket_public_access_block.website_bucket]
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  source       = "${path.module}/website/index.html"
  etag         = filemd5("${path.module}/website/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "styles_css" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "styles.css"
  source       = "${path.module}/website/styles.css"
  etag         = filemd5("${path.module}/website/styles.css")
  content_type = "text/css"
}

resource "aws_s3_object" "scripts_js" {
  bucket = aws_s3_bucket.website_bucket.id
  key    = "scripts.js"
  content = templatefile("${path.module}/templates/scripts.js.tftpl", {
    api_endpoint = aws_api_gateway_stage.dev.invoke_url
  })
  etag         = md5(templatefile("${path.module}/templates/scripts.js.tftpl", { api_endpoint = aws_api_gateway_stage.dev.invoke_url }))
  content_type = "application/javascript"
}

### MP3 bucket ###

resource "aws_s3_bucket" "mp3_bucket" {
  bucket        = local.mp3_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "mp3_bucket" {
  bucket = aws_s3_bucket.mp3_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "mp3_bucket" {
  bucket = aws_s3_bucket.mp3_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "mp3_bucket" {
  bucket = aws_s3_bucket.mp3_bucket.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.mp3_bucket,
    aws_s3_bucket_public_access_block.mp3_bucket,
  ]
}
