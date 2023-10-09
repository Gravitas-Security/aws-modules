data "aws_iam_policy_document" "deny_org_leave" {
  statement {
    sid = "denyOrgLeave"

    effect = "Deny"
    actions = [
      "organizations:LeaveOrganization",
    ]

    resources = [
      "*",
    ]
  }
}