# Whanos Project

Whanos detects a supported app in a Git repo, builds a Docker image, pushes it to a registry, and—when `whanos.yml` has a `deployment`—rolls it out on Kubernetes via Jenkins.

<details>
<summary><strong>Production use cases</strong></summary>

| Scenario | How Whanos helps |
|---|---|
| **Multi-service on Kubernetes** | Each service has its own repo; `link-project` wires build + deploy on the default branch. |
| **Internal platform / PaaS** | Teams push code + optional `whanos.yml`; platform owns Jenkins, registry, and cluster. |
| **Polyglot estates** | Language auto-detection with shared base images; optional custom `Dockerfile`. |
| **Repeatable releases** | Build once, push, deploy the same artifact. |
| **Small ops footprint** | Ansible or Compose recreates the Jenkins control plane from this repo. |

Flow: push → Jenkins poll → build & push image → optional K8s deploy → LoadBalancer (or your ingress).

</details>

You always need: a **registry**, a **Kubernetes cluster** (≥ 2 nodes preferred), and **Jenkins** (Compose locally or Ansible on a VPS).

---

## 1. Shared setup

### Prerequisites

- `kubectl`, Docker + Compose (local Jenkins), Ansible + Debian VPS (VPS path)
- Provider CLI for the path you pick (`doctl`, …)

<details>
<summary><strong>NixOS</strong> — <code>shell.nix</code></summary>

```bash
cd whanos
nix-shell
```

Provides `make`, `kubectl`, `doctl`, `ansible`, `docker-compose`. Docker daemon must be enabled in system NixOS config (user in `docker` group). `KUBECONFIG` is set to `./kubeconfig.yaml`.

```bash
nix-shell --run 'doctl account get'   # one-shot
```

For zsh inside `nix-shell`, use [`any-nix-shell`](https://github.com/haslersn/any-nix-shell).

</details>

### Clone and config

```bash
git clone git@github.com:charlesmadjeri/whanos.git whanos
cd whanos

cp jenkins/.env.example jenkins/.env
cp .env.example .env                                 # DIGITALOCEAN_TOKEN for terraform/doctl
cp ansible/group_vars/all.example.yml ansible/group_vars/all.yml   # VPS only
```

### Credentials

<details>
<summary><strong>Compose</strong> — <code>jenkins/.env</code></summary>

| Variable | Role |
|---|---|
| `JENKINS_ADMIN_PASSWORD` | Jenkins `admin` password |
| `JENKINS_URL` | e.g. `http://localhost:8080` |
| `REGISTRY_HOST` | Hostname only, e.g. `registry.digitalocean.com` |
| `REGISTRY_NAME` | Registry / namespace |
| `REGISTRY_USERNAME` / `REGISTRY_TOKEN` | Registry login |
| `LOCAL_KUBECONFIG_PATH` | Usually `kubeconfig.yaml` |

</details>

<details>
<summary><strong>Ansible</strong> — <code>ansible/group_vars/all.yml</code></summary>

Set `vps_ip`, `jenkins_admin_password`, `jenkins_url`, `registry_*`, and `vps_ssh_private_key_file` (default: project key under `ansible/ssh/`). Optional: `vps_root_password`. Keep `kubeconfig.yaml` at the repo root. See [Ansible playbook](docs/ansible/playbook.md) for generating the VPS key.

</details>

---

## 2. Provider path (pick one)

<details>
<summary><strong>DigitalOcean</strong> — supported path</summary>

**Tools:** [doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/), `kubectl` (NixOS: project `nix-shell`).

```bash
doctl auth init
doctl account get --format Email --no-header   # REGISTRY_USERNAME

doctl registry create whanos --region fra1

doctl kubernetes cluster create whanos \
  --region fra1 --size s-2vcpu-4gb --count 2 --wait

doctl kubernetes cluster kubeconfig save whanos
cp ~/.kube/config ./kubeconfig.yaml

doctl kubernetes cluster registry add whanos
kubectl --kubeconfig=./kubeconfig.yaml apply -f kubernetes/rbac.yaml   # optional
```

```env
REGISTRY_HOST=registry.digitalocean.com
REGISTRY_NAME=whanos
REGISTRY_USERNAME=your.email@example.com
REGISTRY_TOKEN=<do_api_token>
```

Next: [Start Jenkins](docs/jenkins/start-jenkins.md) → [Use Jenkins](docs/jenkins/use-jenkins.md).

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

1. **[Start Jenkins](docs/jenkins/start-jenkins.md)** — Compose (`make run-local`) or Ansible (`make run-ansible`)
2. **[Use Jenkins](docs/jenkins/use-jenkins.md)** — build base images → `link-project` → check deploy

Login: `admin` / password from env. Docs hub: [Documentation](docs/documentation-hub.md).

### Make targets

```bash
make help
make run-local / run-local-build / run-local-down / run-local-restart / run-local-reset
make run-ansible / run-ansible-verbose / run-ansible-very-verbose
make ci-detection / ci-k8s / ci-base-images
make terraform-up ENV=dev / terraform-down ENV=dev / infra ENV=dev
```

Optional cloud bootstrap with Terraform: [docs/terraform.md](docs/terraform.md).

## License

[GNU General Public License v3.0](LICENSE) (GPL-3.0).
