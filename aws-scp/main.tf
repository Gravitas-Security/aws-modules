data "aws_organizations_organization" "org" {}

resource "aws_organizations_policy" "org_scp" {
  for_each    = var.policies
  name        = each.key
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value.policy
  tags_all    = var.defaultTags
}

resource "aws_organizations_policy_attachment" "org_scp_attachment" {
  for_each  = { for scp in local.attachment_map : "${scp.name}_${scp.target_id}" => scp }
  policy_id = aws_organizations_policy.org_scp[each.value.name].id
  target_id = replace(each.key, "${each.value.name}_", "")
}
