resource "aws_s3_bucket" "test-mfa" {
  bucket = "test-mfa-terraform-state"
  acl = "private"
  region = "eu-central-1"
}