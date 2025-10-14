output "n8n_private_ip" {
  value = oci_core_instance.n8n.private_ip
}

output "wireguard_public_ip" {
  value = oci_core_instance.wireguard.public_ip
}
