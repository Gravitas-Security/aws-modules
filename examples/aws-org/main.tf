module "aws-org" {
  source = "github.com/cyberviking949/aws-modules//aws-org?ref=v1.12.0"
  #source = "C:/Users/steve/aws-modules/aws-org"
  aws_accounts = {
    "security" = {
      email = "something@example.com"
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
      policy      = "env_tag.json"
      attachments = ["root"]
    }
    owner_tag = {
      description = "Require owner tag on all AWS services and resources."
      policy      = "owner_tag.json"
      attachments = ["root"]
    }
    contact_tag = {
      description = "Require contact tag on all AWS services and resources."
      policy      = "contact_tag.json"
      attachments = ["root"]
    }
    cost_centre_tag = {
      description = "Require cost-centre tag on all AWS services and resources."
      policy      = "cost_centre_tag.json"
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
