# Whanos

> Detect. Containerize. Ship. Deploy.

Whanos turns a Git push into a language-aware Docker build, a registry push, and—when you want it—a Kubernetes rollout. Jenkins is the control plane; Terraform and Ansible rebuild the platform from this repo.

## Features

| | |
|:---|:---|
| **Language auto-detection** | C · Java · JavaScript/TypeScript · Python · Befunge-93 — one matching criterion or the job fails cleanly |
| **Base + standalone images** | Official Hub bases, slim runtimes, `docker build -t whanos-<lang> - < Dockerfile.base` |
| **Custom Dockerfiles** | Apps may `FROM whanos-<lang>` after bases are built |
| **Private Git** | HTTPS PAT or SSH via `link-project` credentials |
| **SCM every minute** | Linked projects poll, rebuild, and redeploy on change |
| **Optional K8s deploy** | Only when `whanos.yml` has `deployment` — replicas, resources, ports → LoadBalancer |
| **IaC end-to-end** | Terraform: DOCR + DOKS + cheap Jenkins VPS → Ansible: Docker / Casc / Nginx |
| **Local or VPS** | Compose for development; Ansible (or Terraform → Ansible) for defense-ready infra |

```text
  git push ──► Jenkins poll ──► detect lang ──► build & push image
                                      │
                                      └─► whanos.yml? ──► kubectl apply ──► LoadBalancer
```

<details>
<summary><strong>Production use cases</strong></summary>

| Scenario | How Whanos helps |
|---|---|
| **Multi-service on Kubernetes** | Each service has its own repo; `link-project` wires build + deploy on the default branch. |
| **Internal platform / PaaS** | Teams push code + optional `whanos.yml`; platform owns Jenkins, registry, and cluster. |
| **Polyglot estates** | Language auto-detection with shared base images; optional custom `Dockerfile`. |
| **Repeatable releases** | Build once, push, deploy the same artifact. |
| **Small ops footprint** | Terraform provisions DO cloud; Ansible or Compose configures Jenkins. |

</details>

You always need: a **registry**, a **Kubernetes cluster** (≥ 2 nodes preferred), and **Jenkins** (Compose locally or Ansible on a VPS).

---

## 1. Shared setup

### Prerequisites

- `kubectl`, Docker + Compose (local Jenkins), Ansible (VPS path), Terraform (DigitalOcean IaC path)
- Provider CLI: `doctl` (DigitalOcean)

<details>
<summary><strong>NixOS</strong> — <code>shell.nix</code></summary>

```bash
cd whanos
nix-shell
```

Provides `make`, `kubectl`, `doctl`, `ansible`, `terraform`, `docker-compose`. Loads repo-root `.env` when present. Docker daemon must be enabled in system NixOS config (user in `docker` group). `KUBECONFIG` is set to `./kubeconfig.yaml`.

```bash
nix-shell --run 'doctl account get'   # one-shot
```

For zsh inside `nix-shell`, use [`any-nix-shell`](https://github.com/haslersn/any-nix-shell).

</details>

### Clone and config

```bash
git clone git@github.com:charlesmadjeri/whanos.git whanos
cd whanos

cp .env.example .env                                 # all secrets (Compose + Terraform + Ansible)
cp ansible/group_vars/all.example.yml ansible/group_vars/all.yml   # VPS facts (IP, volumes, TLS)
```

### Credentials

<details>
<summary><strong>Repo-root <code>.env</code></strong> — single secrets file</summary>

Used by Compose, Terraform/`doctl`, and Ansible (`lookup('env')`). Gitignored.

| Variable | Role |
|---|---|
| `DIGITALOCEAN_TOKEN` | DO API token (Terraform, doctl; also default `REGISTRY_TOKEN`) |
| `JENKINS_ADMIN_PASSWORD` | Jenkins `admin` password |
| `JENKINS_URL` | Compose only (e.g. `http://localhost:8080`); Ansible uses `http://{{ vps_ip }}` |
| `REGISTRY_HOST` | Hostname only, e.g. `registry.digitalocean.com` |
| `REGISTRY_NAME` | Registry / namespace |
| `REGISTRY_USERNAME` | DO account email |
| `REGISTRY_TOKEN` | Optional; defaults to `DIGITALOCEAN_TOKEN` |
| `LOCAL_KUBECONFIG_PATH` / `KUBECONFIG_PATH` | Compose/Casc paths (usually leave defaults) |

`make terraform-*` / `make run-ansible` load `.env` via `scripts/with-dotenv` (shell-safe for `#` in passwords); `nix-shell` and Compose do the same. Do not put tokens in `terraform.tfvars`.

</details>

<details>
<summary><strong>Ansible facts</strong> — <code>ansible/group_vars/all.yml</code></summary>

Non-secret / host-specific only: `vps_ip`, `vps_ssh_private_key_file`, optional `do_volume_*`, `jenkins_tls_*`. Passwords and registry secrets are read from `.env`.

After **Terraform**, merge `ansible/group_vars/tf.generated.yml` into `all.yml` (IP, registry name, volume paths). Keep `kubeconfig.yaml` at the repo root.

See [Ansible playbook](docs/ansible/playbook.md) and [Terraform](docs/terraform.md).

</details>

---

## 2. Provider path (pick one)

<details>
<summary><strong>DigitalOcean + Terraform</strong> — recommended</summary>

Provisions DOCR + DOKS + Jenkins droplet (cheap lab defaults: **$4/mo** VPS + 5 GiB volume), then Ansible configures Jenkins.

```bash
cp .env.example .env   # DIGITALOCEAN_TOKEN + Jenkins/registry secrets
mkdir -p ansible/ssh
test -f ansible/ssh/whanos_vps || \
  ssh-keygen -t ed25519 -f ansible/ssh/whanos_vps -N "" -C "whanos-vps-ansible"

cp terraform/envs/dev/terraform.tfvars.example terraform/envs/dev/terraform.tfvars
make terraform-plan ENV=dev
make terraform-up ENV=dev

# Merge ansible/group_vars/tf.generated.yml → all.yml (IP / volumes; secrets stay in .env)
make run-ansible
```

Full guide: **[Terraform](docs/terraform.md)** · then [Start Jenkins](docs/jenkins/start-jenkins.md) → [Use Jenkins](docs/jenkins/use-jenkins.md).

Destroy when idle: `make terraform-down ENV=dev`.

</details>

<details>
<summary><strong>DigitalOcean + doctl</strong> — manual bootstrap</summary>

**Tools:** [doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/), `kubectl` (NixOS: project `nix-shell`). Token may come from repo-root `.env` or `doctl auth init`.

```bash
doctl account get --format Email --no-header   # REGISTRY_USERNAME

doctl registry create whanos --region fra1

doctl kubernetes cluster create whanos \
  --region fra1 --size s-2vcpu-4gb --count 2 --wait

doctl kubernetes cluster kubeconfig save whanos
cp ~/.kube/config ./kubeconfig.yaml

doctl kubernetes cluster registry add whanos
kubectl --kubeconfig=./kubeconfig.yaml apply -f kubernetes/rbac.yaml   # optional
```

Create a Debian droplet yourself (lab: `s-1vcpu-512mb-10gb` + 5 GiB volume), install the Ansible SSH pubkey, set `vps_ip` in `all.yml`, then `make run-ansible`.

```env
REGISTRY_HOST=registry.digitalocean.com
REGISTRY_NAME=whanos
REGISTRY_USERNAME=your.email@example.com
REGISTRY_TOKEN=<do_api_token>
```

Next: [Start Jenkins](docs/jenkins/start-jenkins.md) → [Use Jenkins](docs/jenkins/use-jenkins.md). Prefer the [Terraform path](docs/terraform.md) when you want one-command cloud recreate.

</details>

<details>
<summary><strong>Local</strong> — kind/k3d · WIP</summary>

Experimental: no automated Make targets for registry, multi-node cluster, or LoadBalancer.

```bash
docker run -d --restart=always -p 5000:5000 --name whanos-registry registry:2
# REGISTRY_HOST=localhost:5000  REGISTRY_NAME=whanos  (placeholders for user/token)

# kind (≥ 2 workers) or: k3d cluster create whanos --agents 2
# write kubeconfig.yaml, optional: kubectl apply -f kubernetes/rbac.yaml
```

Insecure registry + node pulls + LB are **not automated**. Prefer DigitalOcean for a working path.

Next: [Start Jenkins](docs/jenkins/start-jenkins.md) → [Use Jenkins](docs/jenkins/use-jenkins.md).

</details>

<details>
<summary><strong>GCP / Azure / AWS</strong> · WIP — not validated</summary>

| Cloud | Registry | Cluster |
|---|---|---|
| GCP | Artifact Registry | GKE (≥ 2 nodes) |
| Azure | ACR | AKS (≥ 2 nodes) |
| AWS | ECR (tokens expire ~12h) | EKS (≥ 2 nodes) |

Create registry + cluster, export kubeconfig to `./kubeconfig.yaml`, set `REGISTRY_*`, wire pull permissions. Prefer DigitalOcean until these are tested.

Next: [Start Jenkins](docs/jenkins/start-jenkins.md) → [Use Jenkins](docs/jenkins/use-jenkins.md).

</details>

---

## 3. Jenkins

After registry + cluster + credentials:

1. **[Start Jenkins](docs/jenkins/start-jenkins.md)** — Compose (`make run-local`), Ansible on an existing VPS (`make run-ansible`), or Terraform → Ansible
2. **[Use Jenkins](docs/jenkins/use-jenkins.md)** — build base images → `link-project` → check deploy

Login: `admin` / password from env. Docs hub: [Documentation](docs/documentation-hub.md).

### Make targets

```bash
make help
make run-local / run-local-build / run-local-down / run-local-restart / run-local-reset
make run-ansible / run-ansible-verbose / run-ansible-very-verbose
make terraform-plan ENV=dev / terraform-up ENV=dev / terraform-down ENV=dev / infra ENV=dev
make ci-detection / ci-k8s / ci-base-images
```

## License

[GNU General Public License v3.0](LICENSE) (GPL-3.0).
