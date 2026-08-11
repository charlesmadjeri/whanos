# Ansible

VPS **configure** path for Whanos (UFW → Docker → Jenkins → Nginx).

Cloud resources (registry, DOKS, droplet) are preferably created with **[Terraform](../terraform.md)** first; Ansible then hardens and installs Jenkins on the droplet.

| Doc | Purpose |
|---|---|
| [Playbook](playbook.md) | Order, inventory, variables, Terraform handoff |
| [Roles](roles/roles-hub.md) | Per-role notes |

```bash
# after Terraform (or a manual droplet) + all.yml + kubeconfig.yaml
make run-ansible
make run-ansible-verbose
```

Layout: `ansible/{playbook.yml,inventory.yml,group_vars,roles,collections,ssh}`.

### [Documentation Hub](../documentation-hub.md)
