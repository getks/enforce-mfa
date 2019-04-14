data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "mfa" {
  statement {
    sid = "AllowListActions"
    effect = "Allow"
    actions = [
      "iam:ListUsers",
      "iam:ListVirtualMFADevices"
    ]
    resources = ["*"]
  }
  statement {
    sid = "AllowIndividualUserToListOnlyTheirOwnMFA"
    effect = "Allow"
    actions = [
      "iam:ListMFADevices"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/$${aws:username}",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
    ]
  }
  statement {
      sid = "AllowIndividualUserToManageTheirOwnMFA"
      effect = "Allow"
      actions = [
        "iam:CreateVirtualMFADevice",
        "iam:DeleteVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:ResyncMFADevice"
      ]
      resources = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/$${aws:username}",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
      ]
  }
  statement {
      sid = "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA"
      effect = "Allow"
      actions = [
        "iam:DeactivateMFADevice"
      ]
      resources = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/$${aws:username}",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
      ]
      condition {
        test     = "Bool"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["true"]
      }
  }
  statement {
      sid = "BlockMostAccessUnlessSignedInWithMFA"
      effect = "Deny"
      not_actions = [
        "iam:ListUsers",
        "iam:GetAccountPasswordPolicy",
        "iam:ListVirtualMFADevices",
        "iam:CreateVirtualMFADevice",
        "iam:DeleteVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:ListMFADevices",
        "iam:ResyncMFADevice",
        "iam:ChangePassword"
      ],
      resources = ["*"]
      condition {
        test     = "BoolIfExists"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["false"]
      }
  }
  statement {
      sid = "BlockAllPasswordChangesExceptYourOwnUnlessSignedWithMFA"
      effect = "Deny"
      actions = [
        "iam:CreateVirtualMFADevice",
        "iam:DeleteVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:ListMFADevices",
        "iam:ResyncMFADevice",
        "iam:ChangePassword"
      ]
      not_resources = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/$${aws:username}"
      ]
      condition {
        test     = "BoolIfExists"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["false"]
      }
  }
}

resource "aws_iam_policy" "mfa" {
  name   = "UsersCanOnlyChangePasswordAndMFAUnlessTheyHaveEnabledMFA"
  description = "Users can only change their password and configure MFA devices unless they have enabled MFA"
  policy = "${data.aws_iam_policy_document.mfa.json}"
}
