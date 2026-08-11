# Nginx

Reverse proxy to Jenkins on `127.0.0.1:8080`.

- **HTTP (default):** listen on port **80** (`jenkins_tls_enabled: false`).
- **TLS (prod):** set `jenkins_tls_enabled: true`, `jenkins_tls_cert_path`, `jenkins_tls_key_path`
  (and usually `jenkins_url: https://…`). Nginx redirects 80→443. Install certificates on the
  VPS first (e.g. certbot). UFW opens **443** when TLS is enabled.

[Roles hub](roles-hub.md)
