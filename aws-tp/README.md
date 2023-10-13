# AWS TP Terraform module

Terraform module which creates Tagging Policy resources on AWS.

## Usage

```hcl
module "vpc" {
  module "aws-scp" {
  source = "../../aws-scp"
  policies = {
    deny_root_user = {
      description = "Deny root user access to all AWS services and resources."
      policy      = "file.json"
      attachments = ["r-abcd"]
    }
    deny_leaving_org = {
      description = "Deny root user access to all AWS services and resources."
      policy      = "file2.json"
      attachments = ["r-abcd"]
    }
    deny_admin_policy = {
      description = "Deny root user access to all AWS services and resources."
      policy      = "file3.json"
      attachments = ["ou-abcd-qg1x32t4", "ou-abcd-1snm9bjs"]
    }
  }
}
```

## Tagging Policy
An TP is a policy that specifies the required tags for an AWS account or organization resources. For more information on AWS SCP, please visit: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html


### TP configs

- loads json content from file thats in the root of the child module
  - You MUST remove all WhiteSpaces from the policy, AWS counts them as characters, which result sin an exceeds limit error
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