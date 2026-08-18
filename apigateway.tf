resource "aws_api_gateway_rest_api" "post_reader_api" {
  name = "PostReaderAPI"
}

resource "aws_api_gateway_authorizer" "cognito" {
  name          = "CognitoAuthorizer"
  rest_api_id   = aws_api_gateway_rest_api.post_reader_api.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.clixx_polly.arn]
}

resource "aws_api_gateway_method" "get_posts" {
  rest_api_id   = aws_api_gateway_rest_api.post_reader_api.id
  resource_id   = aws_api_gateway_rest_api.post_reader_api.root_resource_id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.querystring.postId" = false
  }
}

resource "aws_lambda_permission" "apigw_get_posts" {
  statement_id  = "AllowAPIGatewayInvokeGetPosts"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_posts.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.post_reader_api.execution_arn}/*/GET/"
}

resource "aws_api_gateway_integration" "get_posts" {
  rest_api_id             = aws_api_gateway_rest_api.post_reader_api.id
  resource_id             = aws_api_gateway_rest_api.post_reader_api.root_resource_id
  http_method             = aws_api_gateway_method.get_posts.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.get_posts.invoke_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = jsonencode({
      postId = "$input.params('postId')"
    })
  }
}

resource "aws_api_gateway_method_response" "get_posts_200" {
  rest_api_id = aws_api_gateway_rest_api.post_reader_api.id
  resource_id = aws_api_gateway_rest_api.post_reader_api.root_resource_id
  http_method = aws_api_gateway_method.get_posts.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "get_posts_200" {
  rest_api_id = aws_api_gateway_rest_api.post_reader_api.id
  resource_id = aws_api_gateway_rest_api.post_reader_api.root_resource_id
  http_method = aws_api_gateway_method.get_posts.http_method
  status_code = aws_api_gateway_method_response.get_posts_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = "$input.path('$')"
  }

  depends_on = [aws_api_gateway_integration.get_posts]
}

resource "aws_api_gateway_method" "new_post" {
  rest_api_id   = aws_api_gateway_rest_api.post_reader_api.id
  resource_id   = aws_api_gateway_rest_api.post_reader_api.root_resource_id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_lambda_permission" "apigw_new_post" {
  statement_id  = "AllowAPIGatewayInvokeNewPost"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.new_posts.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.post_reader_api.execution_arn}/*/POST/"
}

resource "aws_api_gateway_integration" "new_post" {
  rest_api_id             = aws_api_gateway_rest_api.post_reader_api.id
  resource_id             = aws_api_gateway_rest_api.post_reader_api.root_resource_id
  http_method             = aws_api_gateway_method.new_post.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.new_posts.invoke_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = "$input.json('$')"
  }
}

resource "aws_api_gateway_method_response" "new_post_200" {
  rest_api_id = aws_api_gateway_rest_api.post_reader_api.id
  resource_id = aws_api_gateway_rest_api.post_reader_api.root_resource_id
  http_method = aws_api_gateway_method.new_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "new_post_200" {
  rest_api_id = aws_api_gateway_rest_api.post_reader_api.id
  resource_id = aws_api_gateway_rest_api.post_reader_api.root_resource_id
  http_method = aws_api_gateway_method.new_post.http_method
  status_code = aws_api_gateway_method_response.new_post_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = "\"$input.path('$')\""
  }

  depends_on = [aws_api_gateway_integration.new_post]
}

resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.post_reader_api.id
  resource_id   = aws_api_gateway_rest_api.post_reader_api.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  rest_api_id = aws_api_gateway_rest_api.post_reader_api.id
  resource_id = aws_api_gateway_rest_api.post_reader_api.root_resource_id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.post_reader_api.id
  resource_id = aws_api_gateway_rest_api.post_reader_api.root_resource_id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.post_reader_api.id
  resource_id = aws_api_gateway_rest_api.post_reader_api.root_resource_id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options]
}

resource "aws_api_gateway_deployment" "post_reader_api" {
  rest_api_id = aws_api_gateway_rest_api.post_reader_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.get_posts.id,
      aws_api_gateway_method.get_posts.authorization,
      aws_api_gateway_method.get_posts.authorizer_id,
      aws_api_gateway_integration.get_posts.id,
      aws_api_gateway_integration_response.get_posts_200.id,
      aws_api_gateway_method.new_post.id,
      aws_api_gateway_method.new_post.authorization,
      aws_api_gateway_method.new_post.authorizer_id,
      aws_api_gateway_integration.new_post.id,
      aws_api_gateway_integration_response.new_post_200.id,
      aws_api_gateway_method.options.id,
      aws_api_gateway_integration.options.id,
      aws_api_gateway_integration_response.options_200.id,
      aws_api_gateway_authorizer.cognito.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.get_posts,
    aws_api_gateway_integration.new_post,
    aws_api_gateway_integration.options,
    aws_api_gateway_integration_response.get_posts_200,
    aws_api_gateway_integration_response.new_post_200,
    aws_api_gateway_integration_response.options_200,
  ]
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.post_reader_api.id
  rest_api_id   = aws_api_gateway_rest_api.post_reader_api.id
  stage_name    = "DEV"
}
