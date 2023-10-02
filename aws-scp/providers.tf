terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.18.1"
    }
  }
  cloud {
    organization = "gravitas-security"
    hostname     = "app.terraform.io" # Optional; defaults to app.terraform.io

    workspaces {
      tags = ["aws-infra-scps", "source:cli"]
    }
  }
}

provider "aws" {
  region   = "us-west-2"
  #profile = "gravitas-master"
}