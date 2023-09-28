module "aws-scp" {
  source = "../../aws-scp"
  policies = {
    deny_root_user = {
      description = "Deny root user access to all AWS services and resources."
      policy     = data.aws_iam_policy_document.deny_root.json
      attachments = [
        {
          target_id = "root"
        }
      ]
    }
  }
}