data "aws_ssoadmin_instances" "sso-instance" {}

data "aws_organizations_organization" "org" {}

data "aws_organizations_organizational_units" "ou" {
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

data "aws_organizations_organizational_unit_descendant_accounts" "org" {
  for_each  = { for ou in data.aws_organizations_organizational_units.ou.children : ou.name => ou.id }
  parent_id = each.value
}

resource "aws_ssoadmin_permission_set" "permissions_set" {
  for_each = var.roles

  name             = each.key
  description      = lookup(each.value, "description", null)
  instance_arn     = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  relay_state      = lookup(each.value, "relay_state", null)
  session_duration = lookup(each.value, "session_duration", null)
  tags             = lookup(each.value, "tags", {})
}

resource "aws_ssoadmin_permission_set_inline_policy" "inline_policy" {
  for_each = var.roles

  inline_policy      = each.value.inline_policy
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.permissions_set[each.key].arn
  depends_on = [ 
    aws_ssoadmin_permission_set.permissions_set
    ]
}

resource "aws_ssoadmin_managed_policy_attachment" "policy-attachment" {
  for_each = { for ps in local.ps_policy_maps : "${ps.policy_arn}" => ps }

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  managed_policy_arn = each.key
  permission_set_arn = aws_ssoadmin_permission_set.permissions_set[each.value.name].arn
}

resource "null_resource" "dependency" {
  triggers = {
    dependency_id = join(",", var.identitystore_group_depends_on)
  }
}

data "aws_identitystore_group" "id_store" {
  for_each          = local.group_list
  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.key
    }
  }

  depends_on = [null_resource.dependency]
}

 resource "aws_ssoadmin_account_assignment" "acct-assignment" {
   for_each = { for act in local.assignment_map : "${act.target_id}" => act }
   instance_arn       = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
   permission_set_arn = aws_ssoadmin_permission_set.permissions_set[each.value.name].arn
   principal_id       = data.aws_identitystore_group.id_store[each.value.group].id
   principal_type     = "GROUP"

   target_id   = each.key
   target_type = "AWS_ACCOUNT"
   depends_on = [ 
     aws_ssoadmin_permission_set.permissions_set,
     data.aws_identitystore_group.id_store
     ]
     }
