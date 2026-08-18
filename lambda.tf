data "archive_file" "new_posts" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/post_reader_new_posts"
  output_path = "${path.module}/build/post_reader_new_posts.zip"
}

data "archive_file" "convert_to_audio" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/post_reader_convert_to_audio"
  output_path = "${path.module}/build/post_reader_convert_to_audio.zip"
}

data "archive_file" "get_posts" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/post_reader_get_posts"
  output_path = "${path.module}/build/post_reader_get_posts.zip"
}

resource "aws_lambda_function" "new_posts" {
  function_name    = "PostReader_NewPosts"
  role             = aws_iam_role.lambda_role_for_polly.arn
  handler          = "index.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 10
  filename         = data.archive_file.new_posts.output_path
  source_code_hash = data.archive_file.new_posts.output_base64sha256

  environment {
    variables = {
      DB_TABLE_NAME = aws_dynamodb_table.posts.name
      SNS_TOPIC     = aws_sns_topic.new_posts.arn
    }
  }
}

resource "aws_lambda_function" "convert_to_audio" {
  function_name    = "PostReader_ConvertToAudio"
  role             = aws_iam_role.lambda_role_for_polly.arn
  handler          = "index.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 300
  filename         = data.archive_file.convert_to_audio.output_path
  source_code_hash = data.archive_file.convert_to_audio.output_base64sha256

  environment {
    variables = {
      DB_TABLE_NAME = aws_dynamodb_table.posts.name
      BUCKET_NAME   = aws_s3_bucket.mp3_bucket.bucket
    }
  }
}

resource "aws_lambda_function" "get_posts" {
  function_name    = "PostReader_GetPosts"
  role             = aws_iam_role.lambda_role_for_polly.arn
  handler          = "index.lambda_handler"
  runtime          = var.lambda_runtime
  filename         = data.archive_file.get_posts.output_path
  source_code_hash = data.archive_file.get_posts.output_base64sha256

  environment {
    variables = {
      DB_TABLE_NAME = aws_dynamodb_table.posts.name
    }
  }
}

resource "aws_sns_topic_subscription" "convert_to_audio" {
  topic_arn = aws_sns_topic.new_posts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.convert_to_audio.arn
}

resource "aws_lambda_permission" "sns_invoke_convert_to_audio" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.convert_to_audio.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.new_posts.arn
}
