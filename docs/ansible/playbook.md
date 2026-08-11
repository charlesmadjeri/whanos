# Playbook

```yaml
- hosts: whanos
  become: yes
  roles: [ufw, docker, jenkins, nginx]
```

Order: firewall → Docker → Jenkins → Nginx reverse proxy (HTTP :80 → :8080).

**Run:** `make run-ansible` (vars in `group_vars/all.yml`, host from `inventory.yml`).

Copy from `group_vars/all.example.yml` first. See [roles](roles/roles-hub.md).

### VPS SSH auth (recommended)

Use a **project-local** key (path from `vps_ssh_private_key_file`, default `ansible/ssh/whanos_vps`) — not a hardcoded `~/.ssh/id_*`:

```bash
mkdir -p ansible/ssh
ssh-keygen -t ed25519 -f ansible/ssh/whanos_vps -N "" -C "whanos-vps-ansible"
# add ansible/ssh/whanos_vps.pub to the droplet, then:
ssh -i ansible/ssh/whanos_vps root@$VPS_IP
make run-ansible
```

Details: [`ansible/ssh/README.md`](../../ansible/ssh/README.md). Password auth via `vps_root_password` remains optional.

[Ansible hub](ansible-hub.md)
