# Product Requirements Document: Secure Public Webhooks for n8n

## 1. Introduction/Overview
The current n8n installation is fully isolated within a private network, accessible only via VPN. While this maximizes security, it breaks critical functionality: external services (like GitHub, Stripe, etc.) cannot send data to n8n webhooks, and OAuth authentication flows are difficult to manage.

This feature aims to selectively expose specific n8n webhook endpoints to the public internet via the existing Traefik reverse proxy, while maintaining strict security controls. The main n8n dashboard and editor will remain protected behind the VPN.

## 2. Goals
*   **Enable External Integrations:** Allow external services to trigger n8n workflows via HTTP webhooks.
*   **Maintain Core Security:** Ensure the n8n Editor UI and API remain inaccessible to the public internet.
*   **Secure Webhooks:** Add an optional layer of security (Header Validation) for webhook endpoints where possible.
*   **Simplify OAuth:** Validate that OAuth flows work seamlessly for users connected to the VPN.
*   **HTTPS Support:** Ensure all public traffic is encrypted using Let's Encrypt SSL certificates via Traefik.

## 3. User Stories
*   **As an automation engineer**, I want to receive webhook events from GitHub so that I can trigger a deployment workflow automatically.
*   **As a security engineer**, I want to ensure that only the webhook paths (`/webhook/*`) are exposed publicly, preventing unauthorized access to the n8n dashboard.
*   **As a user**, I want to authenticate my Google Drive node via OAuth while connected to my VPN without errors.
*   **As an admin**, I want to optionally enforce a secret header check on specific webhook endpoints to prevent spam or unauthorized triggers.

## 4. Functional Requirements

### 4.1. Reverse Proxy Configuration (Traefik)
1.  **Public Entrypoint:** Configure a new Traefik router rule to accept traffic on ports 80/443 for the specific n8n domain (e.g., `n8n.yourdomain.com`).
2.  **Path Filtering:**
    *   Allow public access **ONLY** to paths starting with `/webhook/` and `/webhook-test/`.
    *   Block or redirect all other paths (e.g., `/`, `/workflow/*`) to a 403 Forbidden or require VPN access.
3.  **Header Validation Middleware (Optional):**
    *   Create a Traefik middleware that checks for a specific HTTP header (e.g., `X-N8N-Secret`) and value.
    *   Apply this middleware to sensitive webhook routes if required.
4.  **SSL/TLS:**
    *   Automatically provision and renew Let's Encrypt certificates for the public n8n domain.

### 4.2. n8n Configuration
5.  **Environment Variables:**
    *   Set `WEBHOOK_URL` to the public HTTPS domain (e.g., `https://n8n.yourdomain.com/`).
    *   Set `N8N_EDITOR_BASE_URL` (or equivalent) to ensure the editor UI knows it is accessed internally/via VPN.

### 4.3. OAuth Handling
6.  **VPN-Based Auth:**
    *   Document/Verify that OAuth callbacks function correctly when the user is connected to the VPN. The callback URL will be `https://n8n.yourdomain.com/rest/oauth2-credential/callback`, which must be reachable by the user's browser (via VPN) and potentially the external provider (if they validate the target). *Note: Most OAuth providers redirect the browser, so as long as the user is on VPN and can reach the domain, it works.*

## 5. Non-Goals (Out of Scope)
*   **Public Dashboard Access:** The n8n editor UI will NOT be exposed publicly.
*   **Complex Authentication:** No detailed user management or SSO integration for the webhook endpoints themselves beyond token/header checks.
*   **DDoS Protection:** Basic rate limiting is acceptable but enterprise-grade DDoS protection is out of scope (relying on OCI/Cloudflare basic protections).

## 6. Design Considerations
*   **Traefik Rules:** Use Traefik's `PathPrefix` matcher to granularly control access.
    *   `Rule: Host(n8n.domain.com) && PathPrefix(/webhook/)` -> **Allow Public**
    *   `Rule: Host(n8n.domain.com)` -> **VPN Only (Private Entrypoint)**
*   **DNS:** The domain `n8n.yourdomain.com` must resolve to the **Public IP** of the OCI instance (hosting Traefik).

## 7. Technical Considerations
*   **Existing Stack:** Integration with the current `homelab` Ansible/Docker setup.
*   **Domain Control:** User must have control over the domain's DNS records to point to the OCI instance IP.

## 8. Success Metrics
*   External service (e.g., `curl -X POST https://n8n.yourdomain.com/webhook/test`) receives a 200 OK response.
*   Accessing `https://n8n.yourdomain.com/` (root) from a public IP returns a 404 or 403 error.
*   Accessing `https://n8n.yourdomain.com/` while connected to VPN loads the n8n Editor.
*   OAuth credential connection test in n8n passes successfully.

## 9. Open Questions
*   Do you want to apply the "Header Validation" middleware globally to all webhooks, or per-router? (Assumption: Create the middleware but apply it optionally/selectively).
