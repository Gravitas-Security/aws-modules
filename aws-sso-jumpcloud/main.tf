#Create the Jumpcloud Admin group
resource "jumpcloud_user_group" "admin_role_group" {
  name = "aws-role-AdministratorAccess"
}

# Create group for each role
resource "jumpcloud_user_group" "user_groups" {
  for_each = var.roles
  name = format("aws-role-%s", each.key)
}

# Get the AWS Application info from Jumpcloud
data "jumpcloud_application" "aws_sso" {
    name = "AWS IAM Identity Center"
    display_label = "AWS SSO"
}

#Associate the admin group with the application
resource "jumpcloud_user_group_association" "admin_group_association" {
  type      = "application"
  group_id  = jumpcloud_user_group.admin_role_group.id
  object_id = data.jumpcloud_application.aws_sso.id
  depends_on = [ 
    jumpcloud_user_group.admin_role_group,
    data.jumpcloud_application.aws_sso
   ]
}

#Associate the user group with the application
resource "jumpcloud_user_group_association" "user_group_association" {
  for_each = jumpcloud_user_group.user_groups
  type      = "application"
  group_id  = jumpcloud_user_group.user_groups[each.key].id
  object_id = data.jumpcloud_application.aws_sso.id
  depends_on = [ 
    jumpcloud_user_group.user_groups,
    data.jumpcloud_application.aws_sso
   ]
}

resource "time_sleep" "wait_5_seconds" {
  depends_on = [null_resource.dependency]

  create_duration = "5s"
}

## Get data about the SSO instance for use in subsequent steps
data "aws_ssoadmin_instances" "sso-instance" {}

## Get data about the AWS Organization for use in subsequent steps
data "aws_organizations_organization" "org" {}

## Get identity store group for use in assignming AdministratorAccess (must be created via SCIM prior)
data "aws_identitystore_group" "id_store_admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso-instance.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = jumpcloud_user_group.admin_role_group.name
    }
  }
  depends_on = [ 
    jumpcloud_user_group_association.admin_group_association,
    time_sleep.wait_5_seconds ]
}

## Get the default AdministratorAccess permissionset
data "aws_ssoadmin_permission_set" "admin_permission_sets" {
  instance_arn = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  name         = "AdministratorAccess"
  depends_on = [ data.aws_identitystore_group.id_store_admin ]
}

## Assign the AdministratorAccess permission set to every account in org
resource "aws_ssoadmin_account_assignment" "admin_acct_assignment" {
  for_each           = local.org_accounts
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  permission_set_arn = data.aws_ssoadmin_permission_set.admin_permission_sets.arn
  principal_id       = data.aws_identitystore_group.id_store_admin.id
  principal_type     = "GROUP"

  target_id   = local.org_accounts[each.key]
  target_type = "AWS_ACCOUNT"
  depends_on = [
    data.aws_ssoadmin_permission_set.admin_permission_sets,
    data.aws_identitystore_group.id_store
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
  depends_on = [ data.aws_identitystore_group.id_store ]
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

  # If var.k8s_access is true, merge the EKS access policy document with the inline policy. Otherwise, use the inline policy as is
  inline_policy      = each.value.k8s_access == true ? data.aws_iam_policy_document.eks_combined[each.key].json : each.value.inline_policy
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.permissions_set[each.key].arn
  depends_on = [
    aws_ssoadmin_permission_set.permissions_set
  ]
}

## Attach AWS Managed Policies to the permission set
resource "aws_ssoadmin_managed_policy_attachment" "policy-attachment" {
  for_each = { for ps in local.ps_policy_maps : "${ps.name}_${ps.policy_arn}" => ps }

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso-instance.arns)[0]
  managed_policy_arn = format("arn:aws:iam::aws:policy/%s", split("_", each.key)[1])
  permission_set_arn = aws_ssoadmin_permission_set.permissions_set[each.value.name].arn
  depends_on         = [aws_ssoadmin_permission_set.permissions_set]
}

resource "null_resource" "dependency" {
  triggers = {
    dependency_id = join(",", var.identitystore_group_depends_on)
  }
}

## Get identity store group for use in assigning roles (must be created via SCIM prior)
data "aws_identitystore_group" "id_store" {
  for_each          = var.roles
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso-instance.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = format("aws-role-%s", each.key)
    }
  }

  depends_on = [null_resource.dependency]
}

## Assign the identity store group to permission set. Assign permission set to defined account(s)
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