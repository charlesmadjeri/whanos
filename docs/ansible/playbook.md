# Playbook

```yaml
- hosts: whanos
  become: yes
  roles: [ufw, docker, jenkins, nginx]
```

Order: firewall → Docker → Jenkins → Nginx reverse proxy (HTTP :80 → :8080; optional TLS).

**Run:** `make run-ansible` (vars in `group_vars/all.yml`, host from `inventory.yml`).

Copy from `group_vars/all.example.yml` first. See [roles](roles/roles-hub.md).

## After Terraform

If you used [`make terraform-up`](../terraform.md):

1. Terraform writes `ansible/host_vars/whanos.yml` (`vps_ip`, volumes, …). Ansible loads it automatically and **overrides** any stale IP in `all.yml`.
2. Keep secrets in repo-root `.env` (`JENKINS_ADMIN_PASSWORD`, `REGISTRY_*`, `DIGITALOCEAN_TOKEN`).
3. Ensure `vps_ssh_private_key_file` points at `ansible/ssh/whanos_vps` (same key Terraform installed).
4. Ensure `kubeconfig.yaml` exists at the repo root (Terraform writes it).
5. `make run-ansible` (preflight + optional merge; `scripts/with-dotenv` exports `.env`).

`make terraform-down` clears host_vars and blanks leftover IPs in `all.yml` so the next recreate cannot SSH a dead address.

## VPS SSH auth (recommended)

Use a **project-local** key (path from `vps_ssh_private_key_file`, default `ansible/ssh/whanos_vps`) — not a hardcoded `~/.ssh/id_*`:

```bash
mkdir -p ansible/ssh
ssh-keygen -t ed25519 -f ansible/ssh/whanos_vps -N "" -C "whanos-vps-ansible"
# Terraform installs the .pub on the droplet automatically.
# Manual droplet: add ansible/ssh/whanos_vps.pub yourself, then:
ssh -i ansible/ssh/whanos_vps root@$VPS_IP
make run-ansible
```

Details: [`ansible/ssh/README.md`](../../ansible/ssh/README.md). Password auth via `vps_root_password` remains optional.

[Ansible hub](ansible-hub.md) · [Terraform](../terraform.md)
