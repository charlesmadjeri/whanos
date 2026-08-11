# Terraform for Whanos

Optional IaC path that replaces manual `doctl` bootstrap for:

1. **DigitalOcean Container Registry**
2. **DOKS cluster** (write `kubeconfig.yaml`)
3. **Jenkins VPS** (droplet + SSH key + cloud firewall) → hand off to Ansible

## Layout

```
terraform/
  modules/registry
  modules/cluster
  modules/jenkins-vps
  envs/dev     # cheap lab defaults (1-node OK)
  envs/prod    # ≥2 nodes, SSH allowlist, HTTPS firewall, larger droplet
```

## Prerequisites

- [Terraform](https://www.terraform.io/) ≥ 1.5 (`nix-shell` includes it after `shell.nix` update)
- `doctl` authenticated (`DIGITALOCEAN_TOKEN` / `doctl auth init`)
- Project SSH key: `ansible/ssh/whanos_vps` (+ `.pub`) — see [ansible/ssh/README.md](../ansible/ssh/README.md)

## Quick start (dev)

```bash
export DIGITALOCEAN_TOKEN=...   # or DIGITALOCEAN_ACCESS_TOKEN
cp terraform/envs/dev/terraform.tfvars.example terraform/envs/dev/terraform.tfvars
# edit tfvars if needed

make terraform-up ENV=dev
# → kubeconfig.yaml, ansible/inventory.tf.yml, ansible/group_vars/tf.generated.yml

# Merge tf.generated.yml into ansible/group_vars/all.yml (add jenkins_admin_password + registry_*)
make run-ansible
```

## Production (safe defaults)

```bash
cp terraform/envs/prod/terraform.tfvars.example terraform/envs/prod/terraform.tfvars
# MUST set ssh_allow_cidrs to your IP/32
make terraform-up ENV=prod
```

Prod module enforces `cluster_node_count >= 2`, opens 443 when `enable_https = true`, and defaults to a larger Jenkins droplet. TLS certificates are still configured in Ansible/nginx (firewall only opens the port).

## Make targets

| Target | Action |
|---|---|
| `make terraform-init ENV=dev` | `terraform init` |
| `make terraform-plan ENV=dev` | plan |
| `make terraform-up ENV=dev` | apply + DOCR↔DOKS integration |
| `make terraform-down ENV=dev` | destroy |
| `make infra ENV=dev` | terraform-up then remind Ansible handoff |

## Destroy / cost

```bash
make terraform-down ENV=dev
# Optional: python scripts/clean_docr.py   # wipe leftover registry images
```

Droplets, DOKS, and DOCR incur hourly cost — destroy lab stacks when idle.

## Security notes

- State files (`.tfstate`) can contain kubeconfig material — gitignored; prefer a remote backend with lock for teams.
- Never commit `terraform.tfvars`, `kubeconfig.yaml`, or `tf.generated.yml`.
- Do not publish Docker TCP 2375; Compose and Ansible paths were hardened separately.
