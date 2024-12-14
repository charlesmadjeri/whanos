# Whanos Project

## Prerequisites
- Ansible installed on your local machine
- A Debian-based VPS
- SSH access to the VPS

## Initial Setup

1. Clone the repository
2. Copy the example configuration:
   ```bash
   cp ansible/group_vars/all.example.yml ansible/group_vars/all.yml
   ```
3. Configure your variables in `all.yml`:
   ```yaml
   vps_ip: "your_vps_ip"
   vps_root_password: "your_root_password"
   jenkins_admin_password: "your_jenkins_password"
   ```

## Running the Playbook

The project includes several make targets for running the playbook:

```bash
# Run the testing local docker compose to setup the local jenkins and docker setup
make run-local

# Reset the local docker compose setup and run it again
make run-local-reset

# Run Ansible to setup a VPS with jenkins and Docker ready to use
make run-ansible

# Run Ansible with verbose output
make run-ansible-verbose

# Run Ansible with very verbose output (debug mode)
make run-ansible-very-verbose
```

## Documentation

### [Documentation Hub](docs/documentation-hub.md)