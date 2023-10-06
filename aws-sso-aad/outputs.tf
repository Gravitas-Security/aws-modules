output "permission_sets" {
  value = aws_ssoadmin_permission_set.permissions_set
}

output "permission_sets_arn" {
  value = { for k, ps in aws_ssoadmin_permission_set.permissions_set : k => ps.arn }
}

output "assignments" {
  value = aws_ssoadmin_account_assignment.acct-assignment
}

output "groups" {
  value = data.aws_identitystore_group.id_store
}

output "non_master_accounts" {
  value = data.aws_organizations_organization.org.non_master_accounts[*].id
}

output "azuread_groups" {
  value = data.azuread_groups.aad_groups
}

output "azuread_application" {
  value = data.azuread_application.aws_sso
}

output "azuread_service_principal" {
  value = data.azuread_service_principal.aws_sso
}

output "azuread_app_assignments" {
  value = data.azuread_app_role_assignment.group_assignment
}