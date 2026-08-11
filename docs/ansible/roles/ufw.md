# UFW

Opens TCP **22** (SSH) and **80** (HTTP); default deny incoming; enables UFW.

When `jenkins_tls_enabled: true`, also opens **443** (HTTPS). See [Nginx](nginx.md) and [Terraform](../../terraform.md) (`enable_https` on the cloud firewall is separate from UFW).

[Roles hub](roles-hub.md)
