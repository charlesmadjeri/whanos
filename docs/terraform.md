# Terraform for Whanos

Preferred DigitalOcean bootstrap: provision **registry + DOKS + Jenkins VPS** with Terraform, then configure Jenkins with Ansible.

Replaces manual `doctl registry/kubernetes/droplet` steps in the README.

## What it creates

| Module | Resources |
|---|---|
| `modules/registry` | DigitalOcean Container Registry (DOCR) |
| `modules/cluster` | DOKS cluster + writes repo-root `kubeconfig.yaml` (mode `0600`) |
| `modules/jenkins-vps` | Droplet, SSH key, cloud firewall, optional block volume, Ansible inventory snippet |

| Env | Intent |
|---|---|
| `envs/dev` | Cheap lab: `$4/mo` Jenkins droplet + 5 GiB volume; 1-node DOKS OK |
| `envs/prod` | ≥2 DOKS nodes, SSH allowlist, HTTPS firewall port, larger droplet |

```
terraform/
  modules/{registry,cluster,jenkins-vps}/
  envs/{dev,prod}/
```

## Cost notes (dev)

| Resource | Size | Approx |
|---|---|---|
| Jenkins VPS | `s-1vcpu-512mb-10gb`, Debian 13, `fra1` | **$4/mo** |
| Block volume | 5 GiB (Jenkins `/tmp`) | ~$0.50/mo |
| DOKS | 1× `s-1vcpu-2gb` (cheapest lab size) | **dominates the bill** (~$12/mo) — destroy when idle |
| DOCR | `starter` | low / free tier |

The 512 MB droplet needs the volume (tmpfs `/tmp` is too small for Jenkins). Terraform writes `do_volume_*` into `ansible/group_vars/tf.generated.yml` for Ansible.

## Prerequisites

- Tools: `terraform` ≥ 1.5, `doctl`, `make` (`nix-shell` provides them)
- Project SSH key (Terraform installs the **public** key on the droplet):

```bash
mkdir -p ansible/ssh
ssh-keygen -t ed25519 -f ansible/ssh/whanos_vps -N "" -C "whanos-vps-ansible"
# private key stays local (gitignored); public key is referenced by tfvars
```

- Secrets in **repo-root** `.env` (gitignored; see `.env.example`):

```bash
cp .env.example .env
# DIGITALOCEAN_TOKEN=...  JENKINS_ADMIN_PASSWORD=...  REGISTRY_USERNAME=...
```

`make terraform-*`, Compose, `make run-ansible` (`scripts/with-dotenv`), and `nix-shell` load `.env` (also sets `DIGITALOCEAN_ACCESS_TOKEN` for `doctl`). (`jenkins/.env` is deprecated.)

## Quick start (dev)

```bash
cd whanos
nix-shell   # optional but recommended

cp .env.example .env
# edit .env → DIGITALOCEAN_TOKEN + Jenkins/registry secrets

cp terraform/envs/dev/terraform.tfvars.example terraform/envs/dev/terraform.tfvars
# defaults already match the $4 droplet + 5 GiB volume

make terraform-plan ENV=dev    # review
make terraform-up ENV=dev      # apply + DOCR↔DOKS integration attempt
```

### Outputs / generated files (gitignored)

| File | Purpose |
|---|---|
| `kubeconfig.yaml` | Cluster access for Jenkins / local `kubectl` |
| `ansible/group_vars/tf.generated.yml` | `vps_ip`, volumes, optional `registry_name` (infra only) |
| `ansible/inventory.tf.yml` | Optional inventory snippet with the new droplet IP |

## Ansible handoff

1. Merge `ansible/group_vars/tf.generated.yml` into `ansible/group_vars/all.yml` (`vps_ip`, `do_volume_*`, …).
2. Keep secrets in `.env` (`JENKINS_ADMIN_PASSWORD`, `REGISTRY_*`, `DIGITALOCEAN_TOKEN`) — Ansible reads them via `lookup('env')`.
3. Ensure `vps_ssh_private_key_file` points at `ansible/ssh/whanos_vps`.
4. Configure the VPS:

```bash
make run-ansible
```

5. Open `http://<jenkins_ipv4>/` (from `terraform output jenkins_ipv4` or `all.yml`).

Full Jenkins steps: [Start Jenkins](jenkins/start-jenkins.md) → [Use Jenkins](jenkins/use-jenkins.md).

## Production (`ENV=prod`)

```bash
cp terraform/envs/prod/terraform.tfvars.example terraform/envs/prod/terraform.tfvars
# MUST set ssh_allow_cidrs = ["YOUR.IP/32"]
make terraform-plan ENV=prod
make terraform-up ENV=prod
```

Prod enforces `cluster_node_count >= 2`, defaults to a larger Jenkins size, and can open firewall **443** (`enable_https = true`). TLS certificates are still installed/configured in Ansible/nginx (`jenkins_tls_*` in `all.yml`).

## Make targets

| Target | Action |
|---|---|
| `make terraform-init ENV=dev` | `terraform init` |
| `make terraform-plan ENV=dev` | plan |
| `make terraform-up ENV=dev` | apply + registry↔cluster integration |
| `make terraform-down ENV=dev` | destroy |
| `make infra ENV=dev` | `terraform-up` then remind Ansible handoff |

After the first `init`, commit the provider lockfile:

```bash
git add terraform/envs/dev/.terraform.lock.hcl   # and prod when used
git commit -m "chore(terraform): add provider lockfile for dev env"
```

## Destroy / cleanup

```bash
make terraform-down ENV=dev
# Optional leftover images: python scripts/clean_docr.py
```

If you created resources **outside** Terraform earlier, tear them down with `doctl` (droplets, `kubernetes cluster delete --dangerous`, `registry delete`, volumes, LBs) before the next apply so names like `whanos` are free.

## Security notes

- Never commit `.env`, `terraform.tfvars`, `*.tfstate`, `kubeconfig.yaml`, or `tf.generated.yml`.
- State can contain kubeconfig material — use a remote backend + lock for shared/prod use.
- Dev firewall may allow SSH from `0.0.0.0/0`; prod should restrict `ssh_allow_cidrs`.

## Related docs

- [Documentation hub](documentation-hub.md)
- [Ansible playbook](ansible/playbook.md) — configure the droplet after Terraform
- [Ansible SSH key](../ansible/ssh/README.md)
- [Start Jenkins](jenkins/start-jenkins.md)

[README](../README.md)
