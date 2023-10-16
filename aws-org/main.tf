## Get data about the AWS Organization for use in subsequent steps
resource "aws_organizations_organization" "org" {
  feature_set = "ALL"
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "account.amazonaws.com",
    "ssm.amazonaws.com",
    "sso.amazonaws.com",
    "tagpolicies.tag.amazonaws.com",
    "ipam.amazonaws.com",
    "detective.amazonaws.com",
    "auditmanager.amazonaws.com",
    "fms.amazonaws.com",
    "guardduty.amazonaws.com",
    "securitylake.amazonaws.com",
    "securityhub.amazonaws.com",
    "macie.amazonaws.com",
    "inspector2.amazonaws.com",
    "access-analyzer.amazonaws.com"
  ]
}

# Create AWS Organization OU's
resource "aws_organizations_organizational_unit" "org_ous" {
  for_each  = var.ous
  name      = each.key
  parent_id = aws_organizations_organization.org.roots[0].id
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
  depends_on = [aws_organizations_organization.org]
}

resource "aws_organizations_account" "accounts" {
  for_each                   = var.aws_accounts
  name                       = each.key
  email                      = each.value.email
  iam_user_access_to_billing = "ALLOW"
  parent_id                  = each.value.ou == "root" ? aws_organizations_organization.org.roots[0].id : aws_organizations_organizational_unit.org_ous[each.value.ou].id
  close_on_deletion          = each.value.close_on_delete != null ? each.value.close_on_delete : true
  role_name                  = each.value.role_name != null ? each.value.role_name : "OrganizationAccountAccessRole"
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
  depends_on = [
    aws_organizations_organizational_unit.org_ous
  ]
  lifecycle {
    ignore_changes = [
      role_name,
      iam_user_access_to_billing
    ]
  }
}

resource "aws_organizations_delegated_administrator" "delegated_admin" {
  for_each = { for act in local.del_services_map : "${act.name}-${act.service_principal}" => act }
  account_id = aws_organizations_account.accounts[each.value.name].id
  service_principal = "${each.value.service_principal}.amazonaws.com"
  depends_on = [aws_organizations_account.accounts]
}

data "aws_iam_policy_document" "policy_validation" {
  for_each                = var.policies
  source_policy_documents = [file("policies/${each.key}.json")]
}

# Create AWS Service Control Policy
resource "aws_organizations_policy" "org_scp" {
  for_each    = var.policies
  name        = each.key
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.policy_validation[each.key].json
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
  depends_on = [aws_organizations_organizational_unit.org_ous]
}

# Attache AWS SCP to AWS Organization root, ou, or account
resource "aws_organizations_policy_attachment" "org_scp_attachment" {
  for_each  = { for scp in local.scp_attachment_map : "${scp.name}_${scp.target_id}" => scp }
  policy_id = aws_organizations_policy.org_scp[each.value.name].id
  target_id = each.value.target_id == "root" ? aws_organizations_organization.org.roots[0].id : each.value.target_id == can(regex("^[0-9]", each.value.target_id)) ? aws_organizations_account.accounts[each.value.target_id].id : aws_organizations_organizational_unit.org_ous[each.value.target_id].id
}

# Create AWS Tag Policy
resource "aws_organizations_policy" "org_tp" {
  for_each    = var.tag_policies
  name        = each.key
  description = each.value.description
  type        = "TAG_POLICY"
  content     = file("tag_policies/${each.key}.json")
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
}

# Attache AWS SCP to AWS Organization root, ou, or account
resource "aws_organizations_policy_attachment" "org_tp_attachment" {
  for_each  = { for tp in local.tp_attachment_map : "${tp.name}_${tp.target_id}" => tp }
  policy_id = aws_organizations_policy.org_tp[each.value.name].id
  target_id = each.value.target_id == "root" ? aws_organizations_organization.org.roots[0].id : aws_organizations_organizational_unit.org_ous[each.value.target_id].id
}

