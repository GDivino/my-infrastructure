locals {
  default_tags = {
    ManaagedBy = "terraform"
    TFProject = join("//", [
      "github.com/gdivino/my-infrastructure",
      "s3-backend/",
    ])
  }
}

module "terraform_state_backend" {
  source           = "cloudposse/tfstate-backend/aws"
  version          = "1.1.1"
  name             = "jing-infrastructure"
  attributes       = ["state"]
  dynamodb_enabled = true

  force_destroy = false
  tags          = local.default_tags
}
