# Ansible Roles

This directory contains documentation for each role used in the Ansible setup.

## Overview

The Whanos infrastructure uses four main roles:

### [Jenkins](jenkins.md)
- CI/CD server installation and configuration
- Plugin management
- Docker integration
- Configuration as Code setup

### [Nginx](nginx.md)
- Reverse proxy configuration
- SSL/TLS termination
- HTTP traffic handling
- Jenkins proxy settings

### [UFW](ufw.md)
- Firewall configuration
- Port management
- Security rules
- Default policies

### [Docker](docker.md)
- Container runtime installation
- Docker daemon configuration
- Group permissions
- System requirements

## Role Dependencies

1. UFW must be configured first for security
2. Docker is required before Jenkins for container support
3. Jenkins must be running before Nginx configuration
4. Nginx is configured last as the front-end proxy

## Go back to:

### [Ansible Hub](../ansible-hub.md)
