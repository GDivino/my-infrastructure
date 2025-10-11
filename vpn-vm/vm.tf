resource "oci_core_instance" "wireguard" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.A1.Flex"
}
