# Nginx Role

## Overview
Configures Nginx as a reverse proxy for Jenkins, providing HTTP access and potential SSL termination.

## Features
- Reverse proxy configuration
- HTTP traffic handling
- Jenkins upstream configuration
- Default site removal

## Configuration

### Proxy Settings
```nginx
upstream jenkins {
    server 127.0.0.1:8080 fail_timeout=0;
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://jenkins;
        proxy_read_timeout 90;
    }
}
```

### Tasks
- Install Nginx package
- Configure Jenkins proxy
- Remove default site
- Enable new configuration
- Manage service state

### Handlers
- Reload Nginx on configuration changes

## Security Considerations
- Proper header forwarding
- Timeout configuration
- Default site removal

## Go back to:

### [Roles Hub](roles-hub.md)
