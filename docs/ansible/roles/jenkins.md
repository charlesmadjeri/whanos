# Jenkins

Installs Jenkins + JDK 17, copies `jenkins/` and `images/` to the VPS, installs plugins from `plugins.txt`, drops kubeconfig, configures systemd (Casc + registry env), adds `jenkins` to the `docker` group.

Paths: `jenkins_home` (default `/var/lib/jenkins`), `whanos_root` (default `/opt/whanos`).

[Roles hub](roles-hub.md)
