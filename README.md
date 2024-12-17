# Whanos Project

## Prerequisites
- Ansible installed on your local machine
- A Debian-based VPS
- SSH access to the VPS
- A valid Kubernetes configuration file named kubeconfig.yaml in the project root

## Initial Setup

1. Clone the repository
2. Copy the example configuration:
   ```bash
   cp terraform/.env.example terraform/.env
   cp jenkins/.env.example jenkins/.env # Optional, for local development purposes
   ```
3. Configure your variables in `terraform/.env` based on `terraform/.env.example`
4. Copy your Kubernetes config to the project root:
    ```bash
    cp ~/.kube/config kubeconfig.yaml
    ```
5. Configure your credentials in `jenkins/.env` based on `jenkins/.env.example` (only for local development purposes)

## Running the Playbook

The project includes several make targets for running the playbook:

```bash
# Run the terraform to setup the VPS, enough for standard users !
make run-terraform

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