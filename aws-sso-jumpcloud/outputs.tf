output "permission_sets" {
  value = aws_ssoadmin_permission_set.permissions_set
}

output "permission_sets_arn" {
  value = { for k, ps in aws_ssoadmin_permission_set.permissions_set : k => ps.arn }
}

output "assignments" {
  value = aws_ssoadmin_account_assignment.acct-assignment
}

output "admin_permission_set" {
  value = data.aws_ssoadmin_permission_set.admin_permission_sets
}

output "admin_assignments" {
  value = aws_ssoadmin_account_assignment.admin_acct_assignment
}

output "admin_group" {
  value = data.aws_identitystore_group.id_store_admin
}

# output "jumpcloud_admin_group" {
#   value = jumpcloud_user_group.admin_role_group
# }

# output "jumpcloud_user_group" {
#   value = jumpcloud_user_group.user_role_group
# }

output "groups" {
  value = data.aws_identitystore_group.id_store
}

output "non_master_accounts" {
  value = data.aws_organizations_organization.org.non_master_accounts[*].id
}