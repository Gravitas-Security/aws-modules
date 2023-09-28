terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.30"
    }
  }
  cloud {
    organization = "gravitas-security"
    hostname     = "app.terraform.io" # Optional; defaults to app.terraform.io

    workspaces {
      tags = ["aws-infra", "source:cli"]
    }
  }
}

provider "aws" {
  region   = "us-west-2"
  profile = "gravitas-master"
}