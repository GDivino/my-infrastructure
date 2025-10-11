locals {
  default_tags = {
    ManagedBy = "terraform"
    TFProject = join("//", [
      "github.com/gdivino/my-infrastructure",
      "s3-backend/",
    ])
  }
}

module "terraform_state_backend" {
  source           = "cloudposse/tfstate-backend/aws"
  version          = "1.7.0"
  name             = "jing-infrastructure"
  attributes       = ["state"]
  dynamodb_enabled = false

  force_destroy = false
  tags          = local.default_tags
}
