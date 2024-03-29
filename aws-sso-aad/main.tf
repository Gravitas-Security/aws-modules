# Create AzureAD Config
data "azuread_client_config" "client_config" {}

# Create AzureAD Groups based off the role name
resource "azuread_group" "aad_groups" {
  for_each         = var.roles
  display_name     = format("aws-role-%s", each.key)
  owners           = [data.azuread_client_config.client_config.object_id]
  security_enabled = true
}

## Create AzureAD group for AdministratorAccess
resource "azuread_group" "aad_admin_group" {
  display_name     = "aws-role-AdministratorAccess"
  owners           = [data.azuread_client_config.client_config.object_id]
  security_enabled = true
}

#import the AWS SSO Application
data "azuread_application" "aws_sso" {
  display_name = "AWS IAM Identity Center (successor to AWS Single Sign-On)"
}

# Import the AWS SSO Azure Service Principal
data "azuread_service_principal" "aws_sso" {
  display_name = data.azuread_application.aws_sso.display_name
}

## Assign the AdministratorAccess group to the AdministratorAccess role
resource "azuread_app_role_assignment" "admin_group_assignment" {
  app_role_id         = data.azuread_service_principal.aws_sso.app_role_ids["User"]
  principal_object_id = azuread_group.aad_admin_group.object_id
  resource_object_id  = data.azuread_service_principal.aws_sso.object_id
  depends_on = [
    data.azuread_service_principal.aws_sso,
    azuread_group.aad_admin_group
  ]
}

## Assign the AzureAD groups to the AWS SSO Application
resource "azuread_app_role_assignment" "group_assignment" {
  for_each            = azuread_group.aad_groups
  app_role_id         = data.azuread_service_principal.aws_sso.app_role_ids["User"]
  principal_object_id = azuread_group.aad_groups[each.key].object_id
  resource_object_id  = data.azuread_service_principal.aws_sso.object_id
  depends_on = [
    data.azuread_service_principal.aws_sso,
    azuread_group.aad_groups
  ]
}

resource "time_sleep" "wait_5_seconds" {
  for_each = azuread_group.aad_groups
  depends_on = [
    azuread_app_role_assignment.group_assignment,
    azuread_app_role_assignment.admin_group_assignment
  ]

  create_duration = "5s"
}

## Get data for the AWS SSO Instance
data "aws_ssoadmin_instances" "sso-instance" {}

## Get data for the AWS Organization
data "aws_organizations_organization" "org" {}

## Get data for the AWS Identity Store admin group
data "aws_identitystore_group" "id_store_admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso-instance.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = azuread_group.aad_admin_group.display_name
    }
  }

  depends_on = [time_sleep.wait_5_seconds]
}

## Get data for the default AdministratorAccess permission set
data "aws_ssoadmin_permission_set" "admin_permission_sets" {
  instance_arn = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  name         = "AdministratorAccess"
}

## Assign the AdministratorAccess permission set to every account in org
resource "aws_ssoadmin_account_assignment" "admin_acct_assignment" {
  for_each           = { for accounts in local.global_accounts : "${accounts}" => accounts }
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  permission_set_arn = data.aws_ssoadmin_permission_set.admin_permission_sets.arn
  principal_id       = data.aws_identitystore_group.id_store_admin.id
  principal_type     = "GROUP"

  target_id   = each.key
  target_type = "AWS_ACCOUNT"
  depends_on = [
    data.aws_ssoadmin_permission_set.admin_permission_sets,
    data.aws_identitystore_group.id_store_admin
  ]
}

## Create a permission set for each role in the roles map
resource "aws_ssoadmin_permission_set" "permissions_set" {
  for_each = var.roles

  name             = each.key
  description      = lookup(each.value, "description", null)
  instance_arn     = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  relay_state      = lookup(each.value, "relay_state", null)
  session_duration = lookup(each.value, "session_duration", null) != null ? lookup(each.value, "session_duration") : "PT2H"
  tags = merge(
    var.defaultTags,
    var.custom_tags
  )
}

## Policy for the k8s_access bool
data "aws_iam_policy_document" "eks_combined" {
  for_each = var.roles
  source_policy_documents = concat(
    [
      data.aws_iam_policy_document.eks_access.json,
      each.value.inline_policy
    ]
  )
}

## Create inline policy for each role in the roles map
resource "aws_ssoadmin_permission_set_inline_policy" "inline_policy" {
  for_each = var.roles

  # If var.k8s_access is true, merge the EKS access policy document with the inline policy
  # Otherwise, use the inline policy as is
  inline_policy      = each.value.k8s_access == true ? data.aws_iam_policy_document.eks_combined[each.key].json : each.value.inline_policy
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.permissions_set[each.key].arn
  depends_on = [
    aws_ssoadmin_permission_set.permissions_set
  ]
}

## Create a managed policy attachment for each managed policy in the roles map
resource "aws_ssoadmin_managed_policy_attachment" "policy-attachment" {
  for_each = { for ps in local.ps_policy_maps : "${ps.name}_${ps.policy_arn}" => ps }

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  managed_policy_arn = format("arn:aws:iam::aws:policy/%s", split("_", each.key)[1])
  permission_set_arn = aws_ssoadmin_permission_set.permissions_set[each.value.name].arn
  depends_on         = [aws_ssoadmin_permission_set.permissions_set]
}

## Get data for the AWS Identity Store groups
data "aws_identitystore_group" "id_store" {
  for_each          = var.roles
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso-instance.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = format("aws-role-%s", each.key)
    }
  }

  depends_on = [time_sleep.wait_5_seconds]
}

## Create an account assignment for each account in the roles map and assign the identity store group to permission set
resource "aws_ssoadmin_account_assignment" "acct-assignment" {
  for_each           = { for act in local.assignment_map : "${act.name}_${act.target_id}" => act }
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.permissions_set[each.value.name].arn
  principal_id       = local.groups[each.value.name]
  principal_type     = "GROUP"

  target_id   = replace(each.key, "${each.value.name}_", "")
  target_type = "AWS_ACCOUNT"
  depends_on = [
    aws_ssoadmin_permission_set.permissions_set,
    data.aws_identitystore_group.id_store
  ]
}