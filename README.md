# Whanos Project

Whanos builds Docker images for supported languages, pushes them to a container registry, and deploys them to Kubernetes via Jenkins. A push to a Whanos-compatible Git repo is enough to detect the stack, containerize the app, publish the image, and (when `whanos.yml` is present) roll it out on the cluster.

<details>
<summary><strong>Production use cases</strong></summary>

| Scenario | How Whanos helps |
|---|---|
| **Multi-service product on Kubernetes** | Each microservice lives in its own repo; `link-project` wires continuous build + deploy so merges to the default branch land as updated pods without a hand-written pipeline per service. |
| **Internal platform / shared PaaS** | Platform teams expose one Jenkins + registry + cluster; product teams only push code and optional `whanos.yml` (replicas, resources, ports) — no need to own Docker/K8s day-to-day. |
| **Polyglot estates (C, Java, JS, Python, …)** | Language is detected from the repo layout; shared base images keep runtimes consistent across teams while still allowing a custom `Dockerfile` when an app needs extra system deps. |
| **Safer, repeatable releases** | Images are built once, pushed to a registry, then deployed from that artifact — same path for staging and production clusters (swap kubeconfig / registry credentials). |
| **Small ops footprint** | Ansible (or Compose for bring-up) recreates Jenkins and supporting config from the repo, so the CI/CD control plane itself is redeployable after failure or for a new environment. |
| **Private source + private registry** | Works with private Git remotes and cloud or self-hosted registries, which fits company code that must not leave controlled infrastructure. |

Typical flow: developer merges → Jenkins polls the repo → image build & push → Kubernetes Deployment/Service update → traffic reaches the new revision via LoadBalancer (or your ingress layer in front of it).

</details>

Every deployment needs the same three pieces:

1. A **container registry** (cloud or local)
2. A **Kubernetes cluster** (≥ 2 nodes preferred)
3. A **Jenkins host** — Docker Compose or Ansible on a VPS

Scripts use generic `REGISTRY_HOST` / `REGISTRY_NAME` / credentials. Open **one** provider path below.

---

## 1. Shared setup

### Prerequisites

- [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
- Docker and Docker Compose (Jenkins via Compose)
- Ansible + Debian VPS with SSH/root (VPS path only)
- Provider CLI tools from the path you choose

### Clone and copy config files

```bash
git clone <repo-url> whanos
cd whanos

cp jenkins/.env.example jenkins/.env
cp ansible/group_vars/all.example.yml ansible/group_vars/all.yml   # Ansible / VPS only
```

### Credentials

<details>
<summary><strong>Path A — Local Compose</strong> (<code>jenkins/.env</code>)</summary>

| Variable | Description |
|---|---|
| `JENKINS_ADMIN_PASSWORD` | Jenkins login password (`admin` user) |
| `JENKINS_URL` | `http://localhost:8080` for local use |
| `REGISTRY_HOST` | Registry hostname (no scheme), e.g. `registry.digitalocean.com` |
| `REGISTRY_NAME` | Registry / repository namespace |
| `REGISTRY_USERNAME` | Registry login user |
| `REGISTRY_TOKEN` | Registry password or API token |
| `LOCAL_KUBECONFIG_PATH` | Usually `kubeconfig.yaml` (project root) |

</details>

<details>
<summary><strong>Path B — VPS / Ansible</strong> (<code>ansible/group_vars/all.yml</code>)</summary>

Set at least:

- `vps_ip`, `vps_root_password`
- `jenkins_admin_password`, `jenkins_url`
- `registry_host`, `registry_name`, `registry_username`, `registry_token`

Keep `kubeconfig.yaml` in the project root (Ansible copies it to the server).

</details>

### Start Jenkins

Do this **after** the provider path’s registry + cluster + env are ready. Compose mounts `./kubeconfig.yaml` into Jenkins either way.

<details>
<summary><strong>Path A — Docker Compose</strong> (dev / try)</summary>

```bash
make run-local              # start Jenkins + Docker-in-Docker
make run-local-build        # first time or after Jenkins/scripts/Dockerfiles change
make run-local-reset        # wipe volumes, rebuild, start
```

Open [http://localhost:8080](http://localhost:8080) — user `admin`, password from `JENKINS_ADMIN_PASSWORD`.

```bash
make run-local-down
make run-local-restart
docker compose logs -f jenkins
```

</details>

<details>
<summary><strong>Path B — Ansible on a VPS</strong></summary>

```bash
make run-ansible
make run-ansible-verbose
make run-ansible-very-verbose
```

Jenkins is reachable via the URL in `all.yml` (typically through Nginx on the VPS).

</details>

---

## 2. Choose a provider path

<details>
<summary><strong>Local</strong> — Docker + local Kubernetes · <em>Work in progress</em></summary>

> No turnkey `make` target yet for a local multi-node cluster, local registry, or LoadBalancer simulation. Experimental until automated.

Goal: mirror the cloud flow on one machine — Jenkins + DinD (Compose), local registry, local K8s (≥ 2 nodes), and LB access for `Service type: LoadBalancer`.

**Tools:** Docker / Compose, [`kind`](https://kind.sigs.k8s.io/) or [`k3d`](https://k3d.io/), `kubectl`, optional MetalLB.

#### Local container registry

```bash
docker run -d --restart=always -p 5000:5000 --name whanos-registry registry:2
```

```env
REGISTRY_HOST=localhost:5000
REGISTRY_NAME=whanos
REGISTRY_USERNAME=unused
REGISTRY_TOKEN=unused
```

Insecure HTTP registries may need extra Docker daemon config (**not automated**). Scripts still require username/token placeholders. Nodes must be able to pull from the same registry (**WIP**).

#### Local Kubernetes cluster (≥ 2 nodes)

<details>
<summary><strong>kind</strong></summary>

```bash
cat > kind-whanos.yaml <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF

kind create cluster --name whanos --config kind-whanos.yaml
kind get kubeconfig --name whanos > ./kubeconfig.yaml
kubectl --kubeconfig=./kubeconfig.yaml get nodes
```

</details>

<details>
<summary><strong>k3d</strong></summary>

```bash
k3d cluster create whanos --agents 2
k3d kubeconfig get whanos > ./kubeconfig.yaml
kubectl --kubeconfig=./kubeconfig.yaml get nodes
```

</details>

#### LoadBalancer / external access (**WIP**)

Services stay pending unless you add MetalLB (kind), k3d LB / port mappings, or use `NodePort` / port-forward for manual testing. Not wired into the repo yet.

#### Optional RBAC

```bash
kubectl --kubeconfig=./kubeconfig.yaml apply -f kubernetes/rbac.yaml
```

Then fill credentials, [start Jenkins](#start-jenkins), and [use Jenkins](#3-use-jenkins).

</details>

<details>
<summary><strong>DigitalOcean</strong> — documented path (current defaults)</summary>

Aligned with `REGISTRY_HOST=registry.digitalocean.com`.

**Tools:** [DigitalOcean](https://www.digitalocean.com/) account, [`doctl`](https://docs.digitalocean.com/reference/doctl/how-to/install/), `kubectl`  
On NixOS: `nix-shell -p doctl kubectl`

#### API token

1. Open [API tokens](https://cloud.digitalocean.com/account/api/tokens)
2. Generate a token with **Full Access**
3. Save it for `doctl` and for `jenkins/.env` / Ansible

```bash
doctl auth init
doctl account get
doctl account get --format Email --no-header   # REGISTRY_USERNAME
```

#### Container Registry

```bash
doctl registry create whanos --region fra1
```

Endpoint: `registry.digitalocean.com/<registry-name>`.

#### Kubernetes cluster (≥ 2 nodes)

```bash
doctl kubernetes cluster create whanos \
  --region fra1 \
  --size s-2vcpu-4gb \
  --count 2 \
  --wait

doctl kubernetes cluster list
```

#### Save kubeconfig

```bash
doctl kubernetes cluster kubeconfig save whanos
cp ~/.kube/config ./kubeconfig.yaml
kubectl --kubeconfig=./kubeconfig.yaml get nodes
```

#### Allow cluster pulls from the registry

```bash
doctl kubernetes cluster registry add whanos
```

#### Optional RBAC

```bash
kubectl --kubeconfig=./kubeconfig.yaml apply -f kubernetes/rbac.yaml
```

#### Credentials

```env
REGISTRY_HOST=registry.digitalocean.com
REGISTRY_NAME=whanos
REGISTRY_USERNAME=your.email@example.com
REGISTRY_TOKEN=your_digitalocean_api_token
```

For Ansible, set the same as `registry_host`, `registry_name`, `registry_username`, `registry_token`.

Then [start Jenkins](#start-jenkins) and [use Jenkins](#3-use-jenkins).

</details>

<details>
<summary><strong>Google Cloud</strong> · <em>Work in progress</em> — not implemented / not tested</summary>

Outline only. Prefer DigitalOcean until validated.

| Piece | Typical GCP product |
|---|---|
| Registry | Artifact Registry (Docker) |
| Cluster | GKE, ≥ 2 nodes |
| Auth | `gcloud` + service account / workload identity |

```bash
gcloud auth login
gcloud config set project PROJECT_ID

gcloud artifacts repositories create whanos \
  --repository-format=docker \
  --location=REGION

gcloud container clusters create whanos \
  --num-nodes=2 \
  --region=REGION

gcloud container clusters get-credentials whanos --region=REGION
cp ~/.kube/config ./kubeconfig.yaml
```

```env
REGISTRY_HOST=REGION-docker.pkg.dev
REGISTRY_NAME=PROJECT_ID/whanos
REGISTRY_USERNAME=_json_key
REGISTRY_TOKEN=<service-account-json-or-access-token>
```

GKE → Artifact Registry pull permissions and SA wiring are **WIP**.

Then [start Jenkins](#start-jenkins) → [use Jenkins](#3-use-jenkins).

</details>

<details>
<summary><strong>Azure</strong> · <em>Work in progress</em> — not implemented / not tested</summary>

Outline only. Prefer DigitalOcean until validated.

| Piece | Typical Azure product |
|---|---|
| Registry | ACR |
| Cluster | AKS, ≥ 2 nodes |
| Auth | `az`; AKS–ACR attach or pull secret |

```bash
az login
az group create --name whanos-rg --location westeurope

az acr create --resource-group whanos-rg --name whanosregistry --sku Basic

az aks create \
  --resource-group whanos-rg \
  --name whanos \
  --node-count 2 \
  --generate-ssh-keys \
  --attach-acr whanosregistry

az aks get-credentials --resource-group whanos-rg --name whanos
cp ~/.kube/config ./kubeconfig.yaml
```

```env
REGISTRY_HOST=whanosregistry.azurecr.io
REGISTRY_NAME=whanos
REGISTRY_USERNAME=<acr-admin-or-sp-app-id>
REGISTRY_TOKEN=<acr-admin-password-or-sp-secret>
```

ACR admin vs service principal wiring is **WIP**.

Then [start Jenkins](#start-jenkins) → [use Jenkins](#3-use-jenkins).

</details>

<details>
<summary><strong>AWS</strong> · <em>Work in progress</em> — not implemented / not tested</summary>

Outline only. Prefer DigitalOcean until validated.

| Piece | Typical AWS product |
|---|---|
| Registry | ECR |
| Cluster | EKS, ≥ 2 nodes |
| Auth | `aws` CLI; IRSA / node role; `get-login-password` for pushes |

```bash
aws configure

aws ecr create-repository --repository-name whanos --region REGION
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
# REGISTRY_HOST=${ACCOUNT_ID}.dkr.ecr.REGION.amazonaws.com

eksctl create cluster --name whanos --nodes 2 --region REGION
aws eks update-kubeconfig --name whanos --region REGION
cp ~/.kube/config ./kubeconfig.yaml
```

```env
REGISTRY_HOST=<account-id>.dkr.ecr.<region>.amazonaws.com
REGISTRY_NAME=whanos
REGISTRY_USERNAME=AWS
REGISTRY_TOKEN=<password from aws ecr get-login-password>
```

ECR tokens expire (~12h); long-lived push auth and EKS pull permissions are **WIP**.

Then [start Jenkins](#start-jenkins) → [use Jenkins](#3-use-jenkins).

</details>

---

## 3. Use Jenkins

1. **Build base images** — **Whanos base images** → **Build all base images** (or each language job). Images go to `REGISTRY_HOST/REGISTRY_NAME`.
2. **Link a project** — run **link-project** with `GIT_URL`, `PROJECT_NAME`, `GIT_BRANCH` (usually `main`). Examples under `docs/example_apps/whanos_example_apps/`. Private Git: add credentials in Jenkins.
3. **Check the deployment**

   ```bash
   kubectl --kubeconfig=./kubeconfig.yaml get pods,svc,deploy
   ```

   With ports in `whanos.yml`, wait for a LoadBalancer IP (cloud) or use the local LB / port-forward workaround.

---

## Make targets

```bash
make help
make run-local / run-local-build / run-local-down / run-local-restart / run-local-reset
make run-ansible / run-ansible-verbose / run-ansible-very-verbose
```

---

## Documentation

### [Documentation Hub](docs/documentation-hub.md)
