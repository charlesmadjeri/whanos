# Playbook

```yaml
- hosts: whanos
  become: yes
  roles: [ufw, docker, jenkins, nginx]
```

Order: firewall → Docker → Jenkins → Nginx reverse proxy (HTTP :80 → :8080).

**Run:** `make run-ansible` (vars in `group_vars/all.yml`, host from `inventory.yml`).

Copy from `group_vars/all.example.yml` first. See [roles](roles/roles-hub.md).

[Ansible hub](ansible-hub.md)
