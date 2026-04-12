## Relevant Files

- `homelab/variables.tf` - Add `n8n_domain` variable.
- `homelab/ansible.tf` - Pass `n8n_domain` and `n8n_server_ip` to Ansible playbook template.
- `homelab/ansible/site.tpl` - Receive new variables and pass them to the roles/tasks.
- `homelab/ansible/templates/traefik/traefik_dynamic.yml.j2` - Define public/private routers and middleware for n8n.
- `homelab/ansible/templates/n8n-docker-compose.yml.j2` - Update `WEBHOOK_URL` environment variable.

### Notes

- **VPN Subnet:** Based on `wg-easy-docker-compose.yml.j2`, the VPN subnet is `10.42.42.0/24`. We will use this for the IP whitelist middleware.
- **DNS:** The user must manually ensure `n8n_domain` resolves to the public IP of the `vpn_server` (Bastion).

## Instructions for Completing Tasks

**IMPORTANT:** As you complete each task, you must check it off in this markdown file by changing `- [ ]` to `- [x]`.

## Tasks

- [x] 0.0 Create feature branch
  - [x] 0.1 Create and checkout a new branch for this feature (e.g., `git checkout -b feature/secure-n8n-webhooks`)
- [x] 1.0 Update Infrastructure Variables
  - [x] 1.1 Edit `homelab/variables.tf`: Add `variable "n8n_domain" { type = string }`.
  - [x] 1.2 Edit `homelab/ansible.tf`: In `resource "local_file" "ansible_playbook"`, add `n8n_domain = var.n8n_domain` and `n8n_server_ip = oci_core_instance.n8n.private_ip` to the `templatefile` vars.
  - [ ] 1.3 (Manual) Add `n8n_domain = "n8n.yourdomain.com"` to your local `homelab/terraform.tfvars`.
- [x] 2.0 Configure Ansible Playbook (`homelab/ansible/site.tpl`)
  - [x] 2.1 In the `Configure VPN Server` play (hosts: `vpn_server`), add `n8n_domain` and `n8n_server_ip` to `vars`.
  - [x] 2.2 In the `Configure n8n Server` play (hosts: `n8n_server`), add `n8n_domain` to `vars`.
- [x] 3.0 Configure Traefik Routing (`homelab/ansible/templates/traefik/traefik_dynamic.yml.j2`)
  - [x] 3.1 Define an HTTP service named `n8n`:
    ```yaml
    http:
      services:
        n8n:
          loadBalancer:
            servers:
              - url: "http://{{ n8n_server_ip }}:5678"
    ```
  - [x] 3.2 Define a Middleware named `vpn-whitelist`:
    ```yaml
    http:
      middlewares:
        vpn-whitelist:
          ipWhiteList:
            sourceRange:
              - "10.42.42.0/24"  # VPN Subnet
              - "127.0.0.1/32"   # Localhost
    ```
  - [x] 3.3 Define `n8n-secure` router (VPN Only / Full Access):
    ```yaml
    http:
      routers:
        n8n-secure:
          rule: "Host(`{{ n8n_domain }}`)"
          entryPoints:
            - "websecure"
          service: "n8n"
          middlewares:
            - "vpn-whitelist"
          tls:
            certResolver: "letsencrypt"
    ```
  - [x] 3.4 Define `n8n-public` router (Public Webhooks):
    ```yaml
    http:
      routers:
        n8n-public:
          rule: "Host(`{{ n8n_domain }}`) && (PathPrefix(`/webhook/`) || PathPrefix(`/webhook-test/`))"
          entryPoints:
            - "websecure"
          service: "n8n"
          tls:
            certResolver: "letsencrypt"
          # No whitelist middleware here!
    ```
    *Note: Traefik priority rules might require setting `priority` explicitly if the routers overlap, but usually longer rule wins. To be safe, we can add `priority: 100` to public and `90` to private, or rely on matching logic.*
- [x] 4.0 Configure n8n Service (`homelab/ansible/templates/n8n-docker-compose.yml.j2`)
  - [x] 4.1 Update `WEBHOOK_URL`:
    ```yaml
    environment:
      - WEBHOOK_URL=https://{{ n8n_domain }}/
    ```
  - [x] 4.2 Update `N8N_HOST` to `{{ n8n_domain }}`.
- [ ] 5.0 Deployment and Verification
  - [ ] 5.1 Run `terraform init` (to pick up variable changes if needed) and `terraform apply` in `homelab/`.
  - [ ] 5.2 If the `local-exec` doesn't trigger (because instances didn't change), manually run:
    `ansible-playbook -i ansible/inventory.ini ansible/site.yml`
  - [ ] 5.3 Verify `https://n8n.yourdomain.com/webhook/test` responds (Publicly).
  - [ ] 5.4 Verify `https://n8n.yourdomain.com/` is Forbidden (Publicly).
  - [ ] 5.5 Verify `https://n8n.yourdomain.com/` loads Editor (Via VPN).
