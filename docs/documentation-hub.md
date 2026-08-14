# Documentation Hub

| Guide | Purpose |
|---|---|
| [Terraform](terraform.md) | **Recommended** DO bootstrap: DOCR + DOKS + Jenkins VPS → Ansible |
| [Ansible](ansible/ansible-hub.md) | Configure the VPS (UFW, Docker, Jenkins, Nginx) |
| [Jenkins](jenkins/jenkins-hub.md) | Start/use Jenkins, plugins, link-project |

Typical flow on DigitalOcean:

1. [Terraform](terraform.md) — `make terraform-up ENV=dev`
2. Keep secrets in `.env`. Terraform writes `ansible/host_vars/whanos.yml` (droplet IP/volumes).
3. [Ansible](ansible/ansible-hub.md) — `make run-ansible`
4. [Start Jenkins](jenkins/start-jenkins.md) / [Use Jenkins](jenkins/use-jenkins.md)

[README](../README.md)
