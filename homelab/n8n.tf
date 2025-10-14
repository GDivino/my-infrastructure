resource "oci_core_instance" "n8n" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "homelab-n8n-server"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 4
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.private_subnet.id
    assign_public_ip = false
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.instance_image.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.n8n_public_key_path)
  }

  timeouts {
    create = "60m"
  }

  freeform_tags = merge(local.default_tags, {
    project = "vpn"
  })
}
