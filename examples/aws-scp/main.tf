module "aws-scp" {
  source = "../../aws-scp"
  policies = {
    deny_root_user = {
      description = "Deny root user access to all AWS services and resources."
      policy     = data.aws_iam_policy_document.deny_root.json
      attachments = ["r-abcd"]
    }
    deny_leaving_org = {
      description = "Deny root user access to all AWS services and resources."
      policy     = data.aws_iam_policy_document.deny_org_leave.json
      attachments = ["r-abcd"]
    }
    deny_admin_policy = {
      description = "Deny root user access to all AWS services and resources."
      policy     = data.aws_iam_policy_document.deny_admin_policy.json
      attachments = ["ou-abcd-qg1x32t4", "ou-abcd-1snm9bjs"]
    }
  }
}