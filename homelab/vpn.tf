locals {
  default_tags = {
    ManagedBy = "terraform"
    TFProject = join("//", [
      "github.com/gdivino/my-infrastructure",
      "vpn-vm/",
    ])
  }
}

resource "oci_core_instance" "wireguard" {
  display_name        = "homelab-wireguard-server"
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.A1.Flex"
  shape_config {
    ocpus = 1
  }

  freeform_tags = merge(local.default_tags, {
    project = "homelab"
  })
}

resource "oci_core_vcn" "homelab" {
  display_name   = "homelab-vcn"
  compartment_id = var.compartment_id
  cidr_blocks    = ["142.0.0.0/16"]

  freeform_tags = merge(local.default_tags, { project = "homelab" })
}
