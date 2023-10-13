output "aws_scp" {
  value = aws_organizations_policy.org_tp[*]
}

output "scp_attachment" {
  value = aws_organizations_policy_attachment.org_tp_attachment[*]
}