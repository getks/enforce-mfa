locals {
  iam_users = [
    "dev1-mfa@test.de",
    "dev2-mfa@test.de"
  ]
}
resource "aws_iam_user" "app-devs" {
  count = "${length(local.iam_users)}"
  name = "${element(local.iam_users, count.index)}"
}

resource "aws_iam_user_group_membership" "app-devs" {
  count = "${length(local.iam_users)}"
  user = "${aws_iam_user.app-devs.*.name[count.index]}"
  groups = [
    "${aws_iam_group.app-developers.name}",
  ]
}

resource "aws_iam_policy" "app-dev-policy" {
  name        = "app_dev_policy"
  path        = "/"
  description = "Team's access policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*",
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:CreateAccessKey",
        "iam:GetUser",
        "iam:ListAccessKeys",
        "iam:ListUsers"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:iam::*:user/$${aws:username}"
    }
  ]
}
EOF
}

resource "aws_iam_group" "app-developers" {
  name = "AppDevs"
}

data "terraform_remote_state" "iam" {
  backend = "s3"

  config {
    key            = "test-mfa"
    region         = "eu-central-1"
    bucket         = "test-mfa-terraform-state"
  }
}

resource "aws_iam_group_policy_attachment" "mfa" {
  group = "${aws_iam_group.app-developers.name}"
  policy_arn = "${data.terraform_remote_state.iam.mfa_policy_arn}"
}

resource "aws_iam_group_policy_attachment" "app-dev-policy" {
  group = "${aws_iam_group.app-developers.name}"
  policy_arn = "${aws_iam_policy.app-dev-policy.arn}"
}

