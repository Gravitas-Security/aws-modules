locals {
#   ssoadmin_instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
   managed_ps            = { for ps_name, ps_attrs in var.roles : ps_name => ps_attrs if can(ps_attrs.managed_policies) }
   acct_assignments            = { for ps_name, ps_attrs in var.roles : ps_name => ps_attrs if can(ps_attrs.assignments) }
#   customer_managed_ps   = { for ps_name, ps_attrs in var.permission_sets : ps_name => ps_attrs if can(ps_attrs.customer_managed_policies) }
   # create ps_name and managed policy maps list
   ps_policy_maps = flatten([
     for name, attrs in local.managed_ps : [
       for policy in attrs.managed_policies : {
         name    = name
         policy_arn = policy
       } if can(attrs.managed_policies)
     ]
   ])

assignment_map = flatten([
     for name, attrs in local.acct_assignments : [
       for account in attrs.assignments : {
         name   = name
         group = attrs.group
         target_id = account
       } if can(attrs.assignments)
     ]
   ])
#  account_assignments = flatten([
#     for name, attrs in local.acct_assignments : [
#        for assignment in attrs.assignments : {
#          account_id = assignment
#        } if can(attrs.assignments)
#      ]
#    ])

   # create ps_name and customer managed policy maps list
#   customer_ps_policy_maps = flatten([
#     for ps_name, ps_attrs in local.customer_managed_ps : [
#       for policy in ps_attrs.customer_managed_policies : {
#         ps_name     = ps_name
#         policy_name = policy
#       } if can(ps_attrs.customer_managed_policies)
#     ]
#   ])
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso-instance.identity_store_ids)[0]
  group_list = toset([for mapping in var.roles : mapping.group])
   # groups = [for assignment in var.account_assignments : assignment.principal_name if assignment.principal_type == "GROUP"]
    accounts_nested_by_ou = { for ou_name, ou_attributes in data.aws_organizations_organizational_unit_descendant_accounts.org :
    ou_name => { for accounts in ou_attributes.accounts :
      accounts.name => accounts.id
    }
  }
}
