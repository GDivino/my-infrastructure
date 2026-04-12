# Product Requirements Document: OS Hardening for Homelab Instances

## 1. Introduction/Overview
The current homelab instances (VPN/Traefik and n8n) are provisioned with a basic operating system setup. To make them production-ready, it is crucial to implement essential OS-level security hardening measures. This PRD outlines the requirements for securing SSH access, automating security updates, and deploying intrusion prevention tools like Fail2Ban.

## 2. Goals
*   **Enhance SSH Security:** Prevent unauthorized SSH access through best practices.
*   **Automate Security Updates:** Ensure instances automatically receive critical security patches.
*   **Implement Basic Intrusion Prevention:** Block brute-force attacks on services like SSH.
*   **Control Network Access:** Restrict inbound traffic to only necessary ports.

## 3. User Stories
*   **As a security-conscious user**, I want my servers to be automatically updated with the latest security patches so that known vulnerabilities are promptly addressed.
*   **As an administrator**, I want to prevent brute-force attacks against my SSH service so that unauthorized access attempts are mitigated.
*   **As an administrator**, I want to ensure only necessary ports are open to the internet to minimize the attack surface.
*   **As a developer**, I want to access my instances securely via SSH using only key-based authentication.

## 4. Functional Requirements

### 4.1. SSH Hardening
1.  **Disable Root Login:** The system must prevent direct SSH login as the `root` user.
2.  **Disable Password Authentication:** The system must enforce key-based SSH authentication only, disabling password-based login.
3.  **Keep Default SSH Port:** The SSH daemon will continue to listen on the default port **22**.
4.  **Create Dedicated Admin User:** A new user with `sudo` privileges must be created for administrative tasks. The default `ubuntu` user should ideally be locked or disabled for SSH if the new user is the primary access method (optional, but recommended).
5.  **Allow Specific Users:** SSH access must be restricted to the newly created administrative user.

### 4.2. Automated Security Updates
6.  **Unattended Upgrades:** The system must be configured to automatically install security updates without manual intervention.

### 4.3. Intrusion Prevention
7.  **Install Fail2Ban:** Fail2Ban must be installed and configured to monitor SSH logs and automatically ban IP addresses exhibiting brute-force attack patterns.
8.  **Fail2Ban Configuration:** Fail2Ban must be configured to protect the SSH service on the default port (22).

### 4.4. Firewall Configuration (UFW)
9.  **Install UFW:** Uncomplicated Firewall (UFW) must be installed.
10. **Allow Essential Ports:** UFW must be configured to allow inbound traffic only on the following ports:
    *   **SSH:** 22 (TCP)
    *   **HTTP:** 80 (TCP) - For Traefik's redirection.
    *   **HTTPS:** 443 (TCP) - For Traefik and public services.
    *   **WireGuard:** 51820 (UDP) - For VPN tunnels.
    *   **WireGuard UI:** 51821 (TCP) - For wg-easy UI (Note: This might need to be restricted to VPN-only or specific IPs if possible, but for now allow it).
11. **Default Deny:** UFW's default inbound policy must be set to 'deny'.

## 5. Non-Goals (Out of Scope)
*   **Advanced Endpoint Detection & Response (EDR):** This PRD does not include advanced EDR solutions.
*   **Host-based Antivirus/Anti-malware:** Installation and configuration of antivirus software is not part of this scope.
*   **Centralized Log Management:** While logs are used by Fail2Ban, centralized logging is not a goal.
*   **Compliance Auditing:** This PRD does not cover specific compliance standard adherence beyond general hardening.

## 6. Design Considerations
*   **Ansible Automation:** All hardening measures should be implemented via Ansible playbooks to ensure idempotency and ease of deployment across multiple instances.
*   **Modularity:** New Ansible roles or tasks should be created for each hardening aspect (SSH, Fail2Ban, UFW, unattended upgrades).
*   **Variable Driven:** The new admin username should be defined as an Ansible variable to allow for easy changes.

## 7. Technical Considerations
*   **Operating System:** Assumes Ubuntu 22.04 LTS (or similar Debian-based distribution).
*   **Existing Ansible Structure:** Integration with the existing `homelab` Ansible setup in `ansible/site.yml`.
*   **Terraform Integration:** The Ansible playbook is executed by Terraform's `local-exec` provisioner. Security groups in OCI (Terraform) must also be updated to allow traffic on port 22 and 51821/51820.

## 8. Success Metrics
*   Attempting to SSH as `root` results in a rejection.
*   Attempting to SSH with a password for a regular user results in a rejection (after disabling password auth).
*   SSH access is successful only via port 22 with the new admin user and key-based authentication.
*   `sudo apt update && sudo apt upgrade` shows no pending security updates shortly after an update cycle.
*   After multiple failed SSH login attempts from an IP, `sudo fail2ban-client status sshd` shows the IP as banned.
*   `sudo ufw status` shows only the explicitly allowed ports as open.

## 9. Open Questions
*   None.
