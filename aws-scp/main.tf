data "aws_organizations_organization" "org" {}

data "aws_organizations_organizational_unit" "dev_ou" {
  parent_id = data.aws_organizations_organization.org.roots[0].id
  name      = "Non-Production"
}

data "aws_organizations_organizational_unit" "prod_ou" {
  parent_id = data.aws_organizations_organization.org.roots[0].id
  name      = "Production"
}

data "aws_organizations_organizational_units" "ous" {
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_policy" "org_scp" {
    for_each = var.policies
  name    = each.key
  description = each.value.description
  type = "SERVICE_CONTROL_POLICY"
  content = each.value.policy
}

resource "aws_organizations_policy_attachment" "org_scp_attachment" {
  for_each = { for scp in local.attachment_map : "${scp.target_id}_${scp.name}" => scp }
  policy_id = aws_organizations_policy.org_scp[each.value.name].id
  target_id = trimsuffix(each.key, "_${each.value.name}")
}
