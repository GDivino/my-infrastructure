terraform {
  required_version = ">= 1.13.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.16.0"
    }
  }

  backend "s3" {
    encrypt      = true
    bucket       = "jing-infrastructure-state"
    region       = "ap-southeast-1"
    key          = "my-infrastructure/s3-backend/terraform.tfstate"
    use_lockfile = true
    profile      = "jing"
  }
}

provider "aws" {
  region  = "ap-southeast-1"
  profile = "jing"
}
