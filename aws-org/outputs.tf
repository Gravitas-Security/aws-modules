output "aws_org" {
  value = aws_organizations_organization.org
}

output "aws_org_root" {
  value = aws_organizations_organization.org.roots[*]
}

output "aws_accounts" {
  value = aws_organizations_organization.org.accounts[*]
}

output "aws_ous" {
  value = aws_organizations_organizational_unit.org_ous[*]
}

output "aws_scp" {
  value = aws_organizations_policy.org_scp[*]
}

output "scp_attachment" {
  value = aws_organizations_policy_attachment.org_scp_attachment[*]
}

output "aws_tp" {
  value = aws_organizations_policy.org_tp[*]
}

output "tp_attachment" {
  value = aws_organizations_policy_attachment.org_tp_attachment[*]
}

output "delegated_admins" {
  value = aws_organizations_delegated_administrator.delegated_admin[*]
}