# Create AzureAD Config
data "azuread_client_config" "client_config" {}

# Create AzureAD Groups based off the role name
resource "azuread_group" "aad_groups" {
  for_each = var.roles
  display_name     = format("aws-role-%s", each.key)
  owners           = [data.azuread_client_config.client_config.object_id]
  security_enabled = true
}

#import the AWS SSO Application
data "azuread_application" "aws_sso" {
  display_name = "AWS IAM Identity Center (successor to AWS Single Sign-On)"
}

resource "azuread_service_principal" "aws_sso" {
  application_id               = data.azuread_application.aws_sso.application_id
  use_existing = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_app_role_assignment" "group_assignment" {
  for_each = azuread_group.aad_groups
  app_role_id         = azuread_service_principal.aws_sso.app_role_ids["User"]
  principal_object_id = azuread_group.aad_groups[each.key].object_id
  resource_object_id  = azuread_service_principal.aws_sso.object_id
  depends_on = [ 
    azuread_service_principal.aws_sso,
    azuread_group.aad_groups
    ]
}

data "aws_ssoadmin_instances" "sso-instance" {}

data "aws_organizations_organization" "org" {}

data "aws_identitystore_group" "id_store_admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso-instance.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "aws-role-AdministratorAccess"
    }
  }

  depends_on = [null_resource.dependency]
}

data "aws_ssoadmin_permission_set" "admin_permission_sets" {
  instance_arn = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  name         = "AdministratorAccess"
}

 resource "aws_ssoadmin_account_assignment" "admin_acct_assignment" {
   for_each = local.org_accounts
   instance_arn       = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
   permission_set_arn = data.aws_ssoadmin_permission_set.admin_permission_sets.arn
   principal_id       = data.aws_identitystore_group.id_store_admin.id
   principal_type     = "GROUP"

   target_id   = local.org_accounts[each.key]
   target_type = "AWS_ACCOUNT"
   depends_on = [ 
     aws_ssoadmin_permission_set.permissions_set,
     data.aws_identitystore_group.id_store
     ]
     }


resource "aws_ssoadmin_permission_set" "permissions_set" {
  for_each = var.roles

  name             = each.key
  description      = lookup(each.value, "description", null)
  instance_arn     = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  relay_state      = lookup(each.value, "relay_state", null)
  session_duration = lookup(each.value, "session_duration", null) != null ? lookup(each.value, "session_duration") : "PT2H"
  tags             = merge(
    var.defaultTags,
    var.custom_tags
  )
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
  for_each = var.roles
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso-instance.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = format("aws-role-%s", each.key)
    }
  }

  depends_on = [null_resource.dependency]
}

 resource "aws_ssoadmin_account_assignment" "acct-assignment" {
   for_each = { for act in local.assignment_map : "${act.target_id}" => act }
   instance_arn       = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
   permission_set_arn = aws_ssoadmin_permission_set.permissions_set[each.value.name].arn
   principal_id       = local.groups[each.value.name]
   principal_type     = "GROUP"

   target_id   = each.key
   target_type = "AWS_ACCOUNT"
   depends_on = [ 
     aws_ssoadmin_permission_set.permissions_set,
     data.aws_identitystore_group.id_store
     ]
     }