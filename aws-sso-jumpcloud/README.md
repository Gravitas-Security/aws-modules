# AWS SSO Terraform module

Terraform module which creates SSO resources on AWS.

## Usage

```hcl
module "sso" {
  source = "github.com/cyberviking949/aws-modules//aws-sso?ref=v1.4.0"

  roles = {
    SecurityAdmin = {
      description = "Provides full access to AWS services and resources."
      k8s_access = true
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
        "ReadOnlyAccess"
      ]
      assignments = [
        "123456789123",
        "987654321987"
      ]
      inline_policy = data.aws_iam_policy_document.security-admin-policy.json
    }
  }
}

```

## SSO Permission sets

AWS SSO Permission sets is a combination of a Role and a policy which can be applied to an account. 

### Permission ste configs

- attachment of AWS Managed Policies
- binds to identity_store group with name "aws-role-<role_name>"
- creates inline policy defined in data source
- supports multiple attachment states
  - "global": attaches to every account in org. queried dynamically in module
  - "<account_id>": attaches to only the specified accounts


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.19 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.19 |

## Modules

No modules.