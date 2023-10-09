data "aws_iam_policy_document" "deny_root" {
  statement {
    sid = "denyRoot"

    effect = "Deny"
    actions = [
      "*",
    ]

    resources = [
      "*",
    ]
    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"

      values = [
        "arn:aws:iam::*:root",
      ]
    }
  }
}