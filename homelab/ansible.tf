resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/ansible/inventory.tpl", {
    wg_server_ip             = oci_core_instance.wireguard.public_ip
    n8n_server_ip            = oci_core_instance.n8n.private_ip
    wg_ssh_private_key_path  = var.wireguard_private_key_path
    n8n_ssh_private_key_path = var.n8n_private_key_path
  })
  filename = "${path.module}/ansible/inventory.ini"
}

resource "local_file" "ansible_playbook" {
  content = templatefile("${path.module}/ansible/site.tpl", {
    traefik_username = var.traefik_username
    traefik_password = var.traefik_password
  })
  filename = "${path.module}/ansible/site.yml"
}

resource "null_resource" "ansible_provisioner" {
  depends_on = [
    oci_core_instance.wireguard,
    oci_core_instance.n8n,
    local_file.ansible_inventory
  ]

  # This provisioner waits for the bastion (VPN server) to accept SSH connections
  # before attempting to run the main playbook. This ensures the proxy command will work.
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = oci_core_instance.wireguard.public_ip
      private_key = file(var.wireguard_private_key_path)
      timeout     = "5m"
    }
    inline = [
      "echo 'SSH is ready for bastion host. Starting Ansible...'"
    ]
  }

  # This provisioner runs the Ansible playbook from your local machine.
  provisioner "local-exec" {
    command = "SHELL=/bin/bash ansible-playbook -i ${local_file.ansible_inventory.filename} ansible/site.yml"

    # Setting this environment variable is a common practice for CI/CD
    # to prevent Ansible from hanging on an interactive prompt.
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
}
