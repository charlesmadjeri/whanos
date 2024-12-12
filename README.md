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
# Basic run
make run

# Run with verbose output
make run-verbose

# Run with very verbose output (debug mode)
make run-very-verbose
```

## Documentation

### [Documentation Hub](docs/documentation-hub.md)