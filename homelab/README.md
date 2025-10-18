# Homelab Infrastructure Notes

A collection of notes, lessons learned, and troubleshooting tips for my personal homelab setup.

## 1. High-Level Architecture & Design

*   **DNS:** The DNS allows us to map text domains to IP addresses. By adding `A` records, we can add subdomains to our top-level domain and point them to our public IP address (the bastion host).
*   **Reverse Proxy:** The reverse proxy (Traefik) is powerful. It enables traffic routing with secure HTTPS, allowing us to route all traffic to one IP address, which then forwards it to the correct internal service.
*   **VPN (WireGuard):** A VPN allows us to access private IP addresses in an internal network over the public internet.
*   **Cloud Firewall (Security Rules):** Security rules are the cloud equivalent of firewalls. In Oracle Cloud, these are attached to subnets to control traffic.
*   **VPN Tunnels (Split vs. Full):**
    *   A **split tunnel** activates the VPN only for traffic going to specified private IPs.
    *   A **full tunnel** routes all internet traffic through the VPN server.

## 2. Application & Service Deployment

### General Container Configuration

*   To make a containerized service accessible from outside its host machine, the application inside the container must listen on `0.0.0.0`. This applies to services like n8n and wg-easy.
*   Example for exposing n8n's port:
    ```yaml
    ports:
      - "0.0.0.0:5678:5678"
    ```

### Reverse Proxy (Traefik)

*   **SSL/TLS Management (Let's Encrypt):**
    *   Always persist `acme.json` in a volume on the VM. This file stores the Let's Encrypt certificates and should not be accidentally replaced.
    *   **Workaround for Rate Limiting:** To work around certificate rate limits, you can add a new, temporary subdomain to the `Host()` rule (e.g., `Host('''real.domain''') || Host('''dummy.domain''')`). This requires creating a corresponding `A` or `AAAA` DNS record for the new subdomain.

*   **Authentication:**
    *   When using basic auth in Traefik docker compose, the password must be hashed (md5, sha1, or Bcrypt). The `htpasswd` CLI tool is the recommended way to do this.
    *   The format in the compose file is `user:<hashed_password>`.
    *   **Troubleshooting:** If the Traefik dashboard repeatedly prompts for login, it's likely because the password is not correctly hashed or formatted.

### VPN (wg-easy)

*   **Troubleshooting:** A "502 Bad Gateway" error when accessing the `wg-easy` UI can often be fixed by setting the `HOST` environment variable for the container to `0.0.0.0`.

## 3. Operations & Troubleshooting

*   **SSH:**
    *   If `SHELL=zsh` interferes with an `ssh -J` (jump host) command, causing a "no such file or directory" error, prefix the command with `SHELL=/bin/bash`.
    *   Example: `SHELL=/bin/bash ssh -J user@jump.host user@destination.server`
