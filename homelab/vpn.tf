resource "oci_core_instance" "wireguard" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "homelab-wireguard-server"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 4
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.instance_image.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.wireguard_public_key_path)
  }

  timeouts {
    create = "60m"
  }
  preserve_boot_volume = true

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/giodivino.tech@gmail.com"
    "Oracle-Tags.CreatedOn" = "2024-10-07T15:33:34.427Z"
  }
  freeform_tags = merge(local.default_tags, {
    project = "vpn"
  })

  depends_on = [
    oci_core_vcn.wireguard,
    oci_core_subnet.public_subnet
  ]
}
