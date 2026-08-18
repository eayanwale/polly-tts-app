provider "aws" {
  region  = var.AWS_REGION
  profile = "stackprog-dev"

  default_tags {
    tags = {
      ManagedBy   = var.ManagedBy
      Environment = var.ENVIRONMENT
      CreatedBy   = local.RUNNER
      Purpose     = var.usage
    }
  }
}