### Website bucket ###

resource "aws_s3_bucket" "website_bucket" {
  bucket = local.website_bucket_name
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

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.website_bucket.arn}/*"]
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website_bucket]
}

resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/website", "**")

  bucket       = aws_s3_bucket.website_bucket.id
  key          = each.value
  source       = "${path.module}/website/${each.value}"
  etag         = filemd5("${path.module}/website/${each.value}")
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), "application/octet-stream")
}

### MP3 bucket ###

resource "aws_s3_bucket" "mp3_bucket" {
  bucket = local.mp3_bucket_name
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
