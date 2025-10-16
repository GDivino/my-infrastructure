- make sure to add in your private keys using the ssh agent since they are password protected
- always persist the acme.json
    - this is what traefik uses to store the letsencrypt certificate
    - since we're using a docker volume, this should not be replaced if it already exists, and should always be persisted if it already exists.
    - a workaround when we receive the rate limit error when requesting for certificates is to add a new identifier (basically a new host)
    - in order to add a new identifier in traefik, simply add a new domain this way Host(`real.domain`) || Host(`dummy.domain`)
    - when adding a new host, letsencrypt requires an A or AAAA record for that specific subdomain
- SHELL=zsh interfering with the ssh jump command
    - not exactly sure why yet or how but the jump commands returns an error of no such file or directory when zsh is used
    - solution: pass in SHELL=/bin/bash when using ssh jump host command
- I am currently getting a BAD gateway error when accessing vpn.giodivino.dev and when I try to log in to the proxy.giodivino.dev dashboard, it doesn't log me in, it will keep prompting for the username and password
- when passing in basic auth to traefik docker compose, the password must be hashed in either md5, sha1, or Bcrypt
    - the recommended way to hash is to use htpasswd cli tool
- when setting up wg-easy, the HOST env variable is 0.0.0.0 because we are inside of the docker container environment and not in the public internet, where the host is 138.2.75.46
- when setting up the traefik container as well
- in order to provide the proper password for traefik, it's in the format of user:(hashed password) where the hashed password does not need two $$ in docker compose
- fixing n8n to be accessible through a container was simple:
    ```
    ports:
    - "0.0.0.0:5678:5678"
    ```
- if we want to make a container accessible to the public internet, we simply need to type in 0.0.0.0 as its host name
- lessons
    - the DNS name allows us to map text domains to IP addresses
        - by adding A tags, we're adding subdomains, and all we have to do is connect it to our public IP address — the bastion host
    - the reverse proxy is so powerful — it enables traffic routing with secure HTTPS communication we can route all our traffic to one IP address, but have the reverse proxy (traefik, nginx, etc.) route it to our own internal network after
    - a VPN like wireguard allows us to access private IP addresses in an internal network over the public internet
- security rules are our firewall rules in the cloud world
    - in oracle cloud, you attach these security lists to the subnet
