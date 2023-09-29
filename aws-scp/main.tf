data "aws_organizations_organization" "org" {}

resource "aws_organizations_policy" "org_scp" {
    for_each = var.policies
  name    = each.key
  description = each.value.description
  type = "SERVICE_CONTROL_POLICY"
  content = data.aws_iam_policy_document.[each.key].json
}

resource "aws_organizations_policy_attachment" "org_scp_attachment" {
  for_each = { for scp in local.attachment_map : "${scp.target_id}_${scp.name}" => scp }
  policy_id = aws_organizations_policy.org_scp[each.value.name].id
  target_id = trimsuffix(each.key, "_${each.value.name}")
}
