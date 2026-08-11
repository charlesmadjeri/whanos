# Use Jenkins

Requires a running instance ([Start Jenkins](start-jenkins.md)).

## 1. Base images

**Whanos base images** → **Build all base images** (or each `whanos-<lang>`).

Pushes to `REGISTRY_HOST/REGISTRY_NAME`. Languages: `c`, `java`, `javascript`, `python`, `befunge`.

## 2. Link a project

Run **link-project**:

| Param | Meaning |
|---|---|
| `GIT_URL` | HTTPS or SSH |
| `PROJECT_NAME` | Job name under **Projects** |
| `GIT_BRANCH` | Default `main` |
| `PROJECT_ROOT` | Optional path *inside* the repo to the app root (empty = repo root) |
| `GIT_CREDENTIALS` / `GIT_SSH_KEY` | Optional private-repo creds |

Created job: polls every minute → `cd` to `PROJECT_ROOT` → build/push → deploy if `whanos.yml` has `deployment`.

**Private Git:** add a credential in Jenkins, select it in `link-project`.

### Test with example apps (this monorepo)

Point `GIT_URL` at this Whanos repo and set `PROJECT_ROOT` per app (no separate test repos):

| `PROJECT_NAME` | `PROJECT_ROOT` |
|---|---|
| `c-hello-world` | `docs/example_apps/whanos_example_apps/c-hello-world` |
| `java-hello-world` | `docs/example_apps/whanos_example_apps/java-hello-world` |
| `js-hello-world` | `docs/example_apps/whanos_example_apps/js-hello-world` |
| `python-hello-world` | `docs/example_apps/whanos_example_apps/python-hello-world` |
| `befunge-hello-world` | `docs/example_apps/whanos_example_apps/befunge-hello-world` |
| `ts-hello-world` | `docs/example_apps/whanos_example_apps/ts-hello-world` |

Only `ts-hello-world` has `whanos.yml` (builds + deploys). The others build and push only.

Note: SCM poll watches the whole repo, so a push can trigger every linked example job.

## 3. Verify deploy

```bash
kubectl --kubeconfig=./kubeconfig.yaml get pods,svc,deploy
```

With ports: wait for LoadBalancer IP (cloud) or use a local LB / `port-forward`.

## Quick test

1. Build all base images  
2. Link the example apps with `PROJECT_ROOT` as above  
3. Push a commit on the Whanos repo → jobs run within ~1 minute  

[Jenkins hub](jenkins-hub.md)
