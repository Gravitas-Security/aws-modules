## Get data about the AWS Organization for use in subsequent steps
data "aws_organizations_organization" "org" {}

# Create AWS Service Control Policy
resource "aws_organizations_policy" "org_tp" {
  for_each    = var.tag_policies
  name        = each.key
  description = each.value.description
  type        = "TAG_POLICY"
  content     = file("policies/${each.value.policy}")
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
}

# Attache AWS SCP to AWS Organization root, ou, or account
resource "aws_organizations_policy_attachment" "org_tp_attachment" {
  for_each  = { for scp in local.attachment_map : "${scp.name}_${scp.target_id}" => scp }
  policy_id = aws_organizations_policy.org_tp[each.value.name].id
  target_id = replace(each.key, "${each.value.name}_", "")
}
