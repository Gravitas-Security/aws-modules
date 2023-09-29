data "aws_iam_policy_document" "deny_admin_policy" {
  statement {
    sid = "denyAdminPolicy"

    effect = "Deny"
    actions = [
      "iam:AttachGroupPolicy",
      "iam:AttachRolePolicy",
      "iam:AttachUserPolicy",
    ]

    resources = [
      "*",
    ]
    condition {
      test     = "ArnEquals"
      variable = "iam:PolicyARN"

      values = [
        "arn:aws:iam::aws:policy/AdministratorAccess",
      ]
    }
  }
}