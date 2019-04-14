provider "aws" {
  version = "~> 1.3"
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    key = "test-mfa"
    region = "eu-central-1"
    bucket = "test-mfa-terraform-state"
  }
}
