locals {
  managed_ps        = { for ps_name, ps_attrs in var.roles : ps_name => ps_attrs if can(ps_attrs.managed_policies) }
  acct_assignments  = { for ps_name, ps_attrs in var.roles : ps_name => ps_attrs if can(ps_attrs.assignments) }
  groups            = { for name, attrs in data.aws_identitystore_group.id_store : name => attrs.id if can(attrs.id) }
  org_accounts      = { for name, attrs in data.aws_organizations_organization.org.accounts[*] : name => attrs.id if can(attrs.id) }
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso-instance.identity_store_ids)[0]
  global_accounts   = data.aws_organizations_organization.org.accounts[*].id

  # create ps_name and managed policy maps list
  ps_policy_maps = flatten([
    for name, attrs in local.managed_ps : [
      for policy in attrs.managed_policies : {
        name       = name
        policy_arn = policy
      } if can(attrs.managed_policies)
    ]
  ])

  # Create name and account assignment maps list
  assignment_map = flatten([
    for name, attrs in local.acct_assignments : 
      attrs.assignments == ["global"] ? [
        for id in local.global_accounts : {
          name      = name
          target_id = id
        }
      ] : [
        for account_name in attrs.assignments : {
          name      = name
          target_id = local.org_accounts[account_name]
        } if can(local.org_accounts[account_name])
      ]
  ])
}
