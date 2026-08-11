# Ansible

VPS deploy path for Whanos (UFW → Docker → Jenkins → Nginx).

| Doc | Purpose |
|---|---|
| [Playbook](playbook.md) | Order, inventory, variables |
| [Roles](roles/roles-hub.md) | Per-role notes |

```bash
# from repo root, after all.yml + kubeconfig.yaml
make run-ansible
make run-ansible-verbose
```

Layout: `ansible/{playbook.yml,inventory.yml,group_vars,roles,collections}`.

### [Documentation Hub](../documentation-hub.md)
