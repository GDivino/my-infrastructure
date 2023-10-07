terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.20.0"
    }
  }
}

provider "aws" {
  region  = "ap-southeast-1"
  profile = "jing"
}
