variable "AWS_REGION" {
  type    = string
  default = "us-east-1"
}

variable "ManagedBy" {
  type    = string
  default = "Terraform"
}

variable "ENVIRONMENT" {
  type    = string
  default = "dev"
}

variable "lambda_runtime" {
  type    = string
  default = "python3.13"
}

variable "usage" {
  type    = string
  default = "clixx polly tts application"
}