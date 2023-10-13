# AWS Organization Terraform module

Terraform module which creates Org and supporting resources resources on AWS.

## Usage

```hcl
module "aws-org" {
  source = "github.com/cyberviking949/aws-modules//aws-org?ref=v2.0.0"
  #source = "C:/Users/steve/aws-modules/aws-org"
  aws_accounts = {
    "security" = {
      email = "stevensmith@gravitas-sec.com"
      ou    = "security"
    }
  }

  ous = {
    non-production = {
      description = "Ou for all non-prod accounts"
    }
    production = {
      description = "OU for production accounts"
    }
    security = {
      description = "OU for Security accounts"
    }
  }


  policies = {
    deny-root-user = {
      description = "Deny root user access to all AWS services and resources."
      attachments = ["root"]
    }
    deny-leaving-org = {
      description = "Deny root user access to all AWS services and resources."
      attachments = ["root"]
    }
    deny-admin-policy = {
      description = "Deny root user access to all AWS services and resources."
      attachments = ["non-production", "production"]
    }
    require-s3encrypt-policy = {
      description = "Deny root user access to all AWS services and resources."
      attachments = ["root"]
    }
  }

  tag_policies = {
    env_tag = {
      description = "Require env tag on all AWS services and resources."
      attachments = ["root"]
    }
    owner_tag = {
      description = "Require owner tag on all AWS services and resources."
      attachments = ["root"]
    }
    contact_tag = {
      description = "Require contact tag on all AWS services and resources."
      attachments = ["root"]
    }
    cost_centre_tag = {
      description = "Require cost-centre tag on all AWS services and resources."
      attachments = ["root"]
    }
  }


  custom_tags = {
    owner       = "something"
    cost-centre = "something"
    contact     = "something"
    repo        = "https://github.com/CyberViking949/aws-infra/tree/main/aws-scp"
  }
}

```

## Organization
Creates an AWS Organization.
  - Enables both `SERVICE_CONTROL_POLICIES` & `TAG_POLICIES`
  - Adds following service principals
    - "cloudtrail.amazonaws.com",
    - "config.amazonaws.com",
    - "account.amazonaws.com",
    - "ssm.amazonaws.com",
    - "sso.amazonaws.com",
    - "tagpolicies.tag.amazonaws.com",
    - "ipam.amazonaws.com"
  - Enables `feature_set = "ALL"`
  - `close_on_deletion` is `TRUE` by default
  - `role_name` is `OrganizationAccountAccessRole` by default

## AWS Accounts
Creates AWS Organization Member accounts, and places them in the desired OU
  - Sets `iam_user_access_to_billing` to `ALLOW`


## Org OU's
Creates AWS Organization OU's in the root OU

## Service Control Policy (SCP)
An SCP is a policy that specifies the maximum permissions for an AWS account or organization. For more information on AWS SCP, please visit: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html


### SCP configs

- Must be Placed in `policies` directory as a raw json file.
- Can be applied at root, ou, or account level
  - root using `root`
  - ou's using friendly name
  - account using accountid (12 digit number)


## Tagging Policy (TP)
An TP is a policy that specifies the tags for an AWS account or resources. For more information on AWS TP, please visit: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html


### TP configs

- Must be Placed in `tag_policies` directory as a raw json file.
- json file must be clear of whitespace due to a bug is AWS where it counts it as a character
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