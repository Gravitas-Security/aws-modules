module "sso" {
  source = "../../aws-sso"
  roles = {
    SecurityAdmin = {
      description = "Provides full access to AWS services and resources."
      managed_policies = [
        "AdministratorAccess"
      ]
      assignments = [
        "global"
      ]
      inline_policy = data.aws_iam_policy_document.security-admin-policy.json
    }
    DevTeam = {
      description = "Provides full access to AWS services and resources."
      managed_policies = [
        "AdministratorAccess"
      ]
      assignments = [
        "123456789123",
        "987654321987"
      ]
      inline_policy = data.aws_iam_policy_document.security-admin-policy.json
    }
  }
}
