terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "enoch-tf-state-bucket"
    key     = "stack-aut-Clixx/terraform.tfstate"
    region  = "us-east-1"
    profile = "stackprog-dev"
  }
}
