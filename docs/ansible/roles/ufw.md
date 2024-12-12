# UFW Role

## Overview
Configures the Uncomplicated Firewall (UFW) to secure the server while allowing necessary services.

## Features
- Basic firewall setup
- Essential port configuration
- Default deny policy
- Service access control

## Port Configuration

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 22   | TCP      | SSH     | Remote access |
| 80   | TCP      | HTTP    | Web traffic |

## Tasks
```yaml
- Install UFW package
- Configure SSH access
- Configure HTTP access
- Enable firewall with deny policy
```

## Security Considerations
- Default deny all incoming
- Only essential ports opened
- SSH access preserved
- HTTP for web services

## Go back to:

### [Roles Hub](roles-hub.md)
