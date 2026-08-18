resource "aws_cognito_user_pool" "clixx_polly" {
  name = "clixx-polly-users"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }
}

resource "aws_cognito_user_pool_client" "clixx_polly_web" {
  name         = "clixx-polly-web-client"
  user_pool_id = aws_cognito_user_pool.clixx_polly.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["implicit"]
  allowed_oauth_scopes                 = ["openid", "email"]

  callback_urls = [local.site_url]
  logout_urls   = [local.site_url]

  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "clixx_polly" {
  domain       = "clixx-polly-auth"
  user_pool_id = aws_cognito_user_pool.clixx_polly.id
}
