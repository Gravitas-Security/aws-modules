terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.23.0"
    }
  }
  cloud {
    organization = "gravitas-security"
    hostname     = "app.terraform.io" # Optional; defaults to app.terraform.io

    workspaces {
      tags = ["aws-infra-ipam", "source:cli"]
    }
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "gravitas-security"
}