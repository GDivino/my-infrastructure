terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.20.0"
    }
  }

  backend "s3" {
    encrypt        = true
    bucket         = "jing-infrastructure-state"
    region         = "ap-southeast-1"
    key            = "my-infrastructure/identity-center/terraform.tfstate"
    dynamodb_table = "jing-infrastructure-state-lock"
    profile        = "jing"
  }
}

provider "aws" {
  region  = "ap-southeast-1"
  profile = "jing"
}
