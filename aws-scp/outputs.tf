output "aws_scp" {
  value = aws_organizations_policy.org_scp[*]
}

output "scp_attachment" {
  value = aws_organizations_policy_attachment.org_scp_attachment[*]
}