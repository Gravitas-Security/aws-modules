module "sso" {
  source = "../../aws-sso" 
  roles = {
    SecurityAdmin = {
      description      = "Provides full access to AWS services and resources.",
      session_duration = "PT2H",
      managed_policies = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
        ]
      group = "aws-admin"
      assignments = [
        "123456789123", 
        "987654321987"
        ]
      inline_policy = data.aws_iam_policy_document.security-admin-policy.json
    }
}
}
