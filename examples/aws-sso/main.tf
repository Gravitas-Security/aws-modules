module "sso" {
  source = "../../aws-sso" 
  roles = {
    SecurityAdmin = {
      description      = "Provides full access to AWS services and resources.",
      session_duration = "PT2H",
      managed_policies = [
        "arn:aws:iam::aws:policy/AdministratorAccess",
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
        ]
      group = "aws-admin"
      assignments = [
        "808696518247", 
        "047640678298"
        ]
      inline_policy = data.aws_iam_policy_document.security-admin-policy.json
    }
}

# data "aws_iam_policy_document" "EKSAdmin" {
#   statement {
#     sid       = "AllowEKS"
#     actions   = ["eks:*"]
#     resources = ["*"]
#   }
#   statement {
#     sid       = "AllowPassRole"
#     actions   = ["iam:PassRole"]
#     resources = ["*"]
#     condition {
#       test     = "StringEquals"
#       variable = "iam:PassedToService"
#       values   = ["eks.amazonaws.com"]
#     }
#   }
# }
}
