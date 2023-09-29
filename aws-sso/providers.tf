terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.18.1"
    }
  }
}

provider "aws" {
  region   = "us-west-2"
  profile = "gravitas-master"
}
