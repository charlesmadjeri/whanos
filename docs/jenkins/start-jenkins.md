# Start Jenkins

Do this **after** registry credentials and `kubeconfig.yaml` are ready.

Login: `admin` / `JENKINS_ADMIN_PASSWORD` (or `jenkins_admin_password`). Signup is disabled.

## Compose (local)

```bash
make run-local-build        # first time / after Jenkins or images change
make run-local
# http://localhost:8080

make run-local-down | run-local-restart | run-local-reset
docker compose logs -f jenkins
```

## Ansible (VPS)

```bash
make run-ansible            # or run-ansible-verbose
```

Open the URL from `ansible/group_vars/all.yml` (Nginx → Jenkins).

## Check

You should see **Whanos base images**, **Projects**, and root **link-project**.

Next: [Use Jenkins](use-jenkins.md) · [Jenkins hub](jenkins-hub.md)
