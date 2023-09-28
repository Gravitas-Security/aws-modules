locals {
  org = data.aws_organizations_organization.org
  root = data.aws_organizations_organization.org.id
  dev_ou = data.aws_organizations_organizational_unit.dev_ou.id
  prod_ou = data.aws_organizations_organizational_unit.prod_ou.id

  policy_attachments            = { for scp_name, scp_attrs in var.policies : scp_name => scp_attrs if can(scp_attrs.attachments) }

  assignment_map = flatten([
     for name, attrs in local.policy_attachments : [
       for attachment in attrs.attachments : {
         target_id = attachment
       } if can(attrs.attachments)
     ]
   ])
}