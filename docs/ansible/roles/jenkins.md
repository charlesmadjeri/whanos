# Jenkins

Installs Jenkins + OpenJDK 21, copies `jenkins/` and `images/` to the VPS, installs plugins from `plugins.txt`, drops kubeconfig (mode `0600`), configures systemd via `/etc/systemd/system` + `/etc/jenkins/whanos.env` (Casc + registry), adds `jenkins` to the `docker` group.

Paths: `jenkins_home` (default `/var/lib/jenkins`), `whanos_root` (default `/opt/whanos`).

[Roles hub](roles-hub.md)
