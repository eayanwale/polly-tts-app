resource "aws_route53_record" "tts-clixx-subdomain" {
  zone_id = data.aws_route53_zone.root-domain.zone_id
  name    = "tts"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}