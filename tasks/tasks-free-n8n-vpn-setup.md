## Relevant Files

- `free-n8n-vpn/main.tf` - Main Terraform configuration (providers, backend).
- `free-n8n-vpn/variables.tf` - Variable definitions (compartment OCID, region, ssh keys).
- `free-n8n-vpn/network.tf` - VCN, Subnet, and Security List definitions.
- `free-n8n-vpn/compute.tf` - Compute instance resource definition (Always Free ARM shape).
- `free-n8n-vpn/outputs.tf` - Outputs for instance IP to be used by Ansible.
- `free-n8n-vpn/ansible/inventory.ini` - Ansible inventory file (generated or static).
- `free-n8n-vpn/ansible/playbook.yml` - Main Ansible playbook for server configuration.
- `free-n8n-vpn/ansible/templates/docker-compose.yml.j2` - Docker Compose template for `wg-easy` and `n8n`.

### Notes

- This task list assumes the creation of a new project directory `free-n8n-vpn` to implement the specific "Free Tier" requirements without modifying the existing `homelab` project unless explicitly merged later.
- Ensure you have OCI API keys and config setup locally for Terraform authentication.
- The `wg-easy` web UI password will need to be handled securely (e.g., via a variable or prompt).

## Instructions for Completing Tasks

**IMPORTANT:** As you complete each task, you must check it off in this markdown file by changing `- [ ]` to `- [x]`. This helps track progress and ensures you don't skip any steps.

Example:
- `- [ ] 1.1 Read file` → `- [x] 1.1 Read file` (after completing)

Update the file after completing each sub-task, not just after completing an entire parent task.

## Tasks

- [ ] 0.0 Create feature branch
  - [ ] 0.1 Create and checkout a new branch for this feature (e.g., `git checkout -b feature/free-n8n-vpn-setup`)

- [ ] 1.0 Infrastructure Provisioning (Terraform)
  - [ ] 1.1 Create project directory `free-n8n-vpn` and initialize `main.tf` with OCI provider configuration.
  - [ ] 1.2 Create `variables.tf` to define input variables (OCI config profile, region, compartment OCID, ssh public key path).
  - [ ] 1.3 Create `network.tf` to define the VCN, Internet Gateway, Route Table, and a Public Subnet.
  - [ ] 1.4 Configure Security Lists in `network.tf`: Allow Inbound SSH (22) and WireGuard UDP (51820). Allow all Egress. **Ensure** Port 80/443/5678 are NOT exposed publicly.
  - [ ] 1.5 Create `compute.tf` to provision the "Always Free" instance (Shape: `VM.Standard.A1.Flex` or `VM.Standard.E2.1.Micro`) and inject the SSH public key.
  - [ ] 1.6 Create `outputs.tf` to output the public IP of the instance.
  - [ ] 1.7 Add a `local-exec` provisioner in `compute.tf` (or a separate null_resource) to automatically update the Ansible inventory file with the new IP.

- [ ] 2.0 Configuration Management (Ansible)
  - [ ] 2.1 Create `ansible` directory and `ansible.cfg` to configure defaults (host key checking false, python interpreter).
  - [ ] 2.2 Create `playbook.yml` and add a "System Prep" play to update `apt` cache and upgrade packages.
  - [ ] 2.3 Add tasks to `playbook.yml` to install Docker and Docker Compose plugin on the remote host.
  - [ ] 2.4 Add a task to ensure the user (e.g., `ubuntu`) is added to the `docker` group.

- [ ] 3.0 Service Deployment (Docker & Ansible)
  - [ ] 3.1 Create `ansible/templates/docker-compose.yml.j2`.
  - [ ] 3.2 Define `wg-easy` service in the compose file:
    - Image: `ghcr.io/wg-easy/wg-easy`
    - Ports: `51820:51820/udp`, `51821:51821/tcp`
    - Volumes: `~/.wg-easy:/etc/wireguard`
    - Environment: `WG_HOST` (public IP), `PASSWORD` (admin password), `WG_DEFAULT_ADDRESS`.
  - [ ] 3.3 Define `n8n` service in the compose file:
    - Image: `docker.n8n.io/n8nio/n8n`
    - Ports: `5678:5678` (Map to host, but blocked by Security List, OR map to specific internal IP if possible, effectively relying on firewall).
    - Volumes: `~/.n8n:/home/node/.n8n`
    - Environment: `N8N_HOST` (internal IP or hostname), `WEBHOOK_URL`.
  - [ ] 3.4 Add tasks to `playbook.yml` to:
    - Create necessary directories (`~/.wg-easy`, `~/.n8n`).
    - Copy the `docker-compose.yml.j2` template to the server (rendering variables like Public IP and Passwords).
    - Run `docker compose up -d`.

- [ ] 4.0 Verification & Documentation
  - [ ] 4.1 Run `terraform init`, `terraform plan`, and `terraform apply` to provision infrastructure.
  - [ ] 4.2 Run `ansible-playbook -i ansible/inventory.ini ansible/playbook.yml` to configure the server (if not triggered automatically).
  - [ ] 4.3 Verify Security: Ensure port 5678 is NOT accessible via Public IP.
  - [ ] 4.4 Verify VPN: Connect a client using `wg-easy` config and ping the internal server IP.
  - [ ] 4.5 Verify n8n: Access `http://<internal-ip>:5678` over the VPN tunnel.
  - [ ] 4.6 Create `free-n8n-vpn/README.md` documenting prerequisites, variables, and usage instructions.
