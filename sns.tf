resource "aws_sns_topic" "new_posts" {
  name = local.sns_topic_name
}
