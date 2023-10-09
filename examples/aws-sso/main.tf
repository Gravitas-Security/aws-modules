module "sso" {
  source = "../../aws-sso"
  roles = {
    SecurityAdmin = {
      description = "Provides full access to AWS services and resources."
      managed_policies = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
      assignments = [
        "global"
      ]
      inline_policy = data.aws_iam_policy_document.security-admin-policy.json
    }
    DevTeam = {
      description = "Provides full access to AWS services and resources."
      managed_policies = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
      assignments = [
        "808696518247",
        "047640678298"
      ]
      inline_policy = data.aws_iam_policy_document.security-admin-policy.json
    }
  }
}
