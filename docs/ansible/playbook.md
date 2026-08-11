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

1. Merge `ansible/group_vars/tf.generated.yml` into `all.yml` (`vps_ip`, `jenkins_url`, `registry_name`, `do_volume_*`).
2. Set `jenkins_admin_password`, `registry_username`, `registry_token`.
3. Keep `vps_ssh_private_key_file` pointing at `ansible/ssh/whanos_vps` (same key Terraform installed).
4. Ensure `kubeconfig.yaml` exists at the repo root (Terraform writes it).
5. `make run-ansible`

Optional: `ansible/inventory.tf.yml` is also generated; the default `inventory.yml` still works when `vps_ip` is set in `all.yml`.

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
