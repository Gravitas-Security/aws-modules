# AWS SCP Terraform module

Terraform module which creates SCP resources on AWS.

## Usage

```hcl
module "vpc" {
  module "aws-scp" {
  source = "../../aws-scp"
  policies = {
    deny_root_user = {
      description = "Deny root user access to all AWS services and resources."
      policy      = data.aws_iam_policy_document.deny_root.json
      attachments = ["r-abcd"]
    }
    deny_leaving_org = {
      description = "Deny root user access to all AWS services and resources."
      policy      = data.aws_iam_policy_document.deny_org_leave.json
      attachments = ["r-abcd"]
    }
    deny_admin_policy = {
      description = "Deny root user access to all AWS services and resources."
      policy      = data.aws_iam_policy_document.deny_admin_policy.json
      attachments = ["ou-abcd-qg1x32t4", "ou-abcd-1snm9bjs"]
    }
  }
}
```

## SCP
An SCP is a policy that specifies the maximum permissions for an AWS account or organization. For more information on AWS SCP, please visit: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html


### SCP configs

- performs validation of policy document
- can be applied at root, ou, or account level


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.18.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.18.1 |

## Modules

No modules.