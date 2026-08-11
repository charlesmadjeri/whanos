# Start Jenkins

Do this **after** registry credentials and `kubeconfig.yaml` are ready (Terraform, manual doctl, or Compose-only with a mounted kubeconfig).

Login: `admin` / `JENKINS_ADMIN_PASSWORD` (or `jenkins_admin_password`). Signup is disabled.

## Path A — Terraform then Ansible (DigitalOcean)

Recommended full stack:

```bash
make terraform-up ENV=dev
# merge ansible/group_vars/tf.generated.yml into all.yml (+ secrets)
make run-ansible
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

Requires `jenkins/.env` and a readable `./kubeconfig.yaml` (and registry credentials for pushes).

## Path C — Ansible on an existing VPS

Droplet already created (manual or Terraform):

```bash
make run-ansible            # or run-ansible-verbose
```

Open the URL from `ansible/group_vars/all.yml` (Nginx → Jenkins). Optional TLS: `jenkins_tls_*` — see [Nginx role](../ansible/roles/nginx.md).

## Check

You should see **Whanos base images**, **Projects**, and root **link-project**.

Next: [Use Jenkins](use-jenkins.md) · [Jenkins hub](jenkins-hub.md)
