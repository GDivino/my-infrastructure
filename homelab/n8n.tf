# resource "oci_core_instance" "n8n" {
#   display_name        = "homelab-n8n-server"
#   availability_domain = var.availability_domain
#   compartment_id      = var.compartment_id
#   shape               = "VM.standard.A1.Flex"
#   shape_config {
#     ocpus = 1
#   }

#   freeform_tags = merge(local.default_tags, {
#     project = "vpn"
#   })
# }
