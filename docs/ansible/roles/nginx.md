# Nginx

Reverse proxy to Jenkins on `127.0.0.1:8080`.

- **HTTP (default):** listen on port **80** (`jenkins_tls_enabled: false`).
- **TLS (manual certs):** set `jenkins_tls_enabled: true`, `jenkins_tls_cert_path`,
  `jenkins_tls_key_path`, and usually `jenkins_url: https://…`. Nginx redirects 80→443.
- **TLS (Let's Encrypt):** set `jenkins_tls_acme_enabled: true`, `jenkins_tls_acme_email`,
  and `jenkins_tls_server_name` to a DNS hostname whose A record points at the VPS.
  Ansible installs certbot, serves HTTP-01 under `/.well-known/acme-challenge/`, then
  flips nginx to HTTPS. UFW opens **443** when TLS or ACME is enabled.

[Roles hub](roles-hub.md)
