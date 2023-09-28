output "permission_sets" {
  value = aws_ssoadmin_permission_set.permissions_set
}

output "permission_sets_arn" {
  value = {for k, ps in aws_ssoadmin_permission_set.permissions_set : k => ps.arn}
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
