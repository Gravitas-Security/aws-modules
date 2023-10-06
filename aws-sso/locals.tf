locals {
  managed_ps       = { for ps_name, ps_attrs in var.roles : ps_name => ps_attrs if can(ps_attrs.managed_policies) }
  acct_assignments = { for ps_name, ps_attrs in var.roles : ps_name => ps_attrs if can(ps_attrs.assignments) }
  groups           = { for name, attrs in data.aws_identitystore_group.id_store : name => attrs.id if can(attrs.id) }
  org_accounts     = { for name, attrs in data.aws_organizations_organization.org.non_master_accounts[*] : name => attrs.id if can(attrs.id) }
  # create ps_name and managed policy maps list
  ps_policy_maps = flatten([
    for name, attrs in local.managed_ps : [
      for policy in attrs.managed_policies : {
        name       = name
        policy_arn = policy
      } if can(attrs.managed_policies)
    ]
  ])

  assignment_map = flatten([
    for name, attrs in local.acct_assignments : [
      for account in attrs.assignments : {
        name      = name
        target_id = account
      } if can(attrs.assignments)
    ]
  ])
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso-instance.identity_store_ids)[0]

  #org_accounts = data.aws_organizations_organization.org.accounts[*].id
}