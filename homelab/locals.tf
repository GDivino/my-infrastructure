locals {
  default_tags = {
    ManagedBy = "terraform"
    TFProject = join("//", [
      "github.com/gdivino/my-infrastructure",
      "vpn-vm/",
    ])
  }
}
