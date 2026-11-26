# Epic PRD: Homelab Security Remediation

## 1. Epic Name

**Homelab Security Remediation**

---

## 2. Goal

- **Problem:** The OCI homelab (`homelab/`) runs a production-facing automation stack (WireGuard VPN bastion, Traefik reverse proxy, and private-subnet n8n server) whose underlying network topology is sound, but several exposed management surfaces and configuration defaults create critical security gaps. Today, the `wg-easy` admin UI is reachable over plain HTTP on port `51821` without a configured admin password, the Traefik dashboard (`proxy.giodivino.dev`) is publicly accessible behind basic auth alone while mounting `/var/run/docker.sock`, public n8n webhook routes execute workflows with zero request authentication, the private OCI security list permits ingress from the entire VCN (`142.0.0.0/16`), and deployment files expose plaintext secrets and relaxed TLS/SSH verification.
- **Solution:** Deliver a risk-ordered security remediation epic across Terraform and Ansible in `homelab/` in two milestones: (1) lock down all publicly reachable management and webhook surfaces (`wg-easy`, Traefik dashboard, public n8n webhooks + end-to-end webhook/OAuth verification), and (2) tighten OCI private subnet security lists and remediate configuration/secrets hygiene.
- **Impact:** Eliminates unauthenticated internet access to homelab admin planes and webhook execution, prevents lateral movement across the VCN, and removes credential/config exposure from Terraform and Ansible workflows.

---

## 3. User Personas

- **Homelab Administrator (Primary Operator):** Solo engineer/owner managing OCI Terraform, Ansible playbooks, WireGuard VPN clients via `wg-easy`, and Traefik routing.
- **Automation Engineer (n8n Builder):** Operator building n8n workflows over VPN, managing OAuth credentials, and connecting external third-party webhook integrations.
- **External Webhook Producer (System Actor):** Automated third-party services (e.g., GitHub, Stripe) posting HTTP payloads to `https://n8n.giodivino.dev/webhook/*`.

---

## 4. High-Level User Journeys

1. **Protected Admin Plane Access:**
   - The Homelab Administrator connects to WireGuard over UDP `51820`.
   - Over VPN, the administrator manages peers at `https://vpn.giodivino.dev` (strong admin password + Traefik protection; direct TCP `51821` closed) and inspects proxy state at `https://proxy.giodivino.dev` (VPN allowlist + basic auth).
   - Direct internet requests to `:51821` or `proxy.giodivino.dev` are rejected.
2. **Authenticated Public Webhooks & Private Editor Access:**
   - External services send webhook requests to `https://n8n.giodivino.dev/webhook/*` with a valid `X-N8N-Secret` header; Traefik validates the header and forwards to n8n.
   - Requests missing or failing the secret header receive a `4xx` response without running a workflow.
   - Public requests to root/non-webhook paths (`https://n8n.giodivino.dev/`) return `403`/`404`; VPN clients load the n8n Editor and complete OAuth credential callbacks without error.
3. **Least-Privilege VCN & Clean Deployment Runs:**
   - Only the public subnet/bastion can reach the private n8n host on `5678` and `22`.
   - Running `terraform apply` and `ansible-playbook` uses proper SSH `known_hosts` verification, avoids writing plaintext passwords into generated files, enforces strict TLS backend verification, and keeps `n8n-data` directories private (`0700`).

---

## 5. Business Requirements

### Functional Requirements

#### Milestone 1 — Public Surface Lockdown (`GDI-10`, `GDI-11`, `GDI-6`)
- **Protect `wg-easy` Admin UI (`GDI-10`):**
  - Remove TCP `51821` ingress from the OCI public security list and remove host port `51821` publication in Docker Compose.
  - Route `wg-easy` exclusively through Traefik HTTPS (`https://vpn.giodivino.dev`) protected by basic auth and/or `vpn-allowlist` middleware.
  - Set a strong, non-default admin password managed outside version control, while preserving active VPN client connectivity.
- **Restrict Traefik Dashboard to VPN (`GDI-11`):**
  - Apply `vpn-allowlist` middleware to the `api` router (`proxy.giodivino.dev`) in addition to existing basic auth.
  - Evaluate whether the Docker provider is still needed; remove `/var/run/docker.sock` mount if file-provider routing suffices.
- **Enforce Public n8n Webhook Validation & Complete Verification (`GDI-6`):**
  - Add a Traefik middleware validating the `X-N8N-Secret` header and attach it to the `n8n-public` router (`/webhook/*`, `/webhook-test/*`), with secret managed like other Traefik secrets.
  - Configure n8n webhook authentication so exposed workflows require the secret.
  - Verify end-to-end runtime behavior (closing out `tasks/tasks-prd-secure-n8n-webhooks.md` §5.0): valid webhook returns `200`, missing secret returns `4xx`, public root returns `403`/`404`, and VPN editor + OAuth callback succeed.

#### Milestone 2 — Network & Hygiene (`GDI-8`, `GDI-12`)
- **Tighten OCI Private Security Lists (`GDI-8`):**
  - Narrow port `5678` ingress from `142.0.0.0/16` to the public subnet (`142.0.1.0/24`).
  - Narrow SSH (`22`) ingress so only the bastion reaches the n8n host (or explicitly document residual risk).
- **Remediate Configuration & Secrets Hygiene (`GDI-12`):**
  - Remove `serversTransport.insecureSkipVerify` from `traefik.yml`.
  - Replace `ANSIBLE_HOST_KEY_CHECKING=False` in `homelab/ansible.tf` with `known_hosts` verification/bootstrapping.
  - Stop baking plaintext `traefik_password` into the generated `homelab/ansible/site.yml` (pass via env or Ansible Vault at runtime).
  - Create `n8n` data directories with mode `0700`.
  - Remove unnecessary `SYS_MODULE` capability from the `wg-easy` container.

### Non-Functional Requirements

- **IaC Idempotency:** All changes live in Terraform (`homelab/*.tf`) and Ansible templates (`homelab/ansible/*.tpl`, `homelab/ansible/templates/*`) and pass `terraform validate`, `terraform plan`, and `ansible-playbook --check --diff`.
- **Zero Service Regression:** Existing WireGuard peers, Let's Encrypt certificates, and n8n workflows/data remain intact.
- **Secrets Hygiene:** Zero credentials, secrets, or keys committed to git or written in plaintext to generated artifacts.

---

## 6. Success Metrics

- Direct TCP `51821` is closed externally; `https://vpn.giodivino.dev` and `https://proxy.giodivino.dev` reject non-VPN/unauthenticated traffic and work over VPN.
- Unauthenticated webhook calls to `https://n8n.giodivino.dev/webhook/*` return `4xx`; authenticated calls return `200 OK`; root returns `403`/`404` publicly and loads Editor + OAuth over VPN.
- OCI private security list has zero `142.0.0.0/16` ingress rules; Traefik→n8n and Ansible jump-host paths remain operational.
- Generated `site.yml` contains zero plaintext passwords; `n8n-data` directories are `0700`; `insecureSkipVerify`, `ANSIBLE_HOST_KEY_CHECKING=False`, and `SYS_MODULE` are removed.

---

## 7. Out of Scope

- **Host OS Hardening (`Homelab OS Hardening`, `P-GDI-3`):** Tracked as a companion epic under the `Homelab` initiative (`tasks/prd-os-hardening.md`), covering SSH hardening, dedicated `sudo` admin user, `unattended-upgrades`, Fail2Ban, and UFW.
- **AWS `s3-backend` Distributed State Locking (`GDI-7`):** Cross-repo AWS state improvement tracked in the `Product` project (`P-GDI-2`).
- **Single-VM Free n8n VPN Setup (`tasks/prd-free-n8n-vpn-setup.md`):** Superseded by the existing two-VM `homelab/` architecture.
- **Enterprise WAF/DDoS, EDR, Antivirus, SIEM, or SSO for Webhooks:** Explicitly excluded.

---

## 8. Business Value

- **Rating:** **High**
- **Justification:** Closing internet-exposed management interfaces (`wg-easy` on `:51821`, Traefik with `docker.sock`) and authenticating public n8n webhooks eliminates the highest-probability paths to full bastion compromise, unauthorized code execution, and private VCN lateral movement.
