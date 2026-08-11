# Ansible VPS SSH key (not committed)

Generate a dedicated key for the test VPS (do not reuse your personal `~/.ssh/id_*`):

```bash
mkdir -p ansible/ssh
ssh-keygen -t ed25519 -f ansible/ssh/whanos_vps -N "" -C "whanos-vps-ansible"
```

## With Terraform (recommended)

Terraform reads `ansible/ssh/whanos_vps.pub` (see `ssh_public_key_path` in `terraform/envs/*/terraform.tfvars`) and registers it on the droplet. You only need the **private** key locally for `make run-ansible`.

Guide: [docs/terraform.md](../../docs/terraform.md).

## Manual droplet

Install the **public** key yourself:

- DigitalOcean: paste into the droplet’s SSH keys at create time, or
- `ssh-copy-id -i ansible/ssh/whanos_vps.pub root@<vps_ip>`

`group_vars` sets `vps_ssh_private_key_file` to `{{ inventory_dir }}/ssh/whanos_vps` by default (override in `all.yml` if you rename the file).
