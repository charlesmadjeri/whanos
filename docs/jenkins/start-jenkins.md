# Start Jenkins

Do this **after** registry credentials and `kubeconfig.yaml` are ready (Terraform, manual doctl, or Compose-only with a mounted kubeconfig).

Login: `admin` / value of `JENKINS_ADMIN_PASSWORD` in repo-root `.env`. Signup is disabled.

## Path A — Terraform then Ansible (DigitalOcean)

Recommended full stack:

```bash
make terraform-up ENV=dev
make run-ansible   # host_vars/whanos.yml supplies the new droplet IP
# http://<vps_ip>/
```

Details: [Terraform](../terraform.md) · [Ansible playbook](../ansible/playbook.md).

## Path B — Compose (local)

```bash
make run-local-build        # first time / after Jenkins or images change
make run-local
# http://localhost:8080

make run-local-down | run-local-restart | run-local-reset
docker compose logs -f jenkins
```

Requires repo-root `.env` (from `.env.example`) and a readable `./kubeconfig.yaml`.

## Path C — Ansible on an existing VPS

Droplet already created (manual or Terraform):

```bash
make run-ansible            # or run-ansible-verbose
```

Open the URL from `ansible/group_vars/all.yml` (Nginx → Jenkins). Optional TLS: `jenkins_tls_*` — see [Nginx role](../ansible/roles/nginx.md).

## Check

You should see **Whanos base images**, **Projects**, and root **link-project**.

Next: [Use Jenkins](use-jenkins.md) · [Jenkins hub](jenkins-hub.md)
