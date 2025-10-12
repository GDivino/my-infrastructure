terraform {
  required_version = ">=1.13.3"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "7.22.0"
    }
  }

  backend "s3" {
    encrypt      = true
    bucket       = "jing-infrastructure-state"
    region       = "ap-southeast-1"
    key          = "my-infrastructure/vpn-vm/terraform.tfstate"
    use_lockfile = true
    profile      = "jing"
  }
}

provider "oci" {
  auth                 = "APIKey"
  region               = "ap-singapore-1"
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.user_ocid
  private_key_password = var.private_key_password
  private_key_path     = var.private_key_path
  fingerprint          = var.fingerprint
}
