terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region   = "us-west-2"
  ignore_tags {
    key_prefixes = ["kubernetes.io/cluster/"]
  }
}

provider "aws" {
  alias = "tgw_account"
  region   = "us-west-2"
}

provider "aws" {
  alias = "vpcx_account"
  region   = "us-west-2"
}