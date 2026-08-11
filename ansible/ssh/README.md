# Ansible VPS SSH key (not committed)

Generate a dedicated key for the test VPS (do not reuse your personal `~/.ssh/id_*`):

```bash
mkdir -p ansible/ssh
ssh-keygen -t ed25519 -f ansible/ssh/whanos_vps -N "" -C "whanos-vps-ansible"
```

Install the **public** key on the droplet (`ansible/ssh/whanos_vps.pub`):

- DigitalOcean: paste into the droplet’s SSH keys, or
- `ssh-copy-id -i ansible/ssh/whanos_vps.pub root@<vps_ip>`

`group_vars` sets `vps_ssh_private_key_file` to `{{ playbook_dir }}/ssh/whanos_vps` by default (override in `all.yml` if you rename the file).
