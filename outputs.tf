output "api_invoke_url" {
  value = aws_api_gateway_stage.dev.invoke_url
}

output "website_bucket_endpoint" {
  value = aws_s3_bucket_website_configuration.website_bucket.website_endpoint
}

output "mp3_bucket_name" {
  value = aws_s3_bucket.mp3_bucket.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.posts.name
}

output "clixx_tts_url" {
  value = "https://${aws_route53_record.tts-clixx-subdomain.name}.${data.aws_route53_zone.root-domain.name}"
}