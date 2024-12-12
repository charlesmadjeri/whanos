# Jenkins Role

## Overview
Installs and configures Jenkins CI server with necessary plugins and configurations for the Whanos infrastructure.

## Features
- Automated installation of Jenkins and Java
- Plugin management using plugin manager
- Docker integration
- Configuration as Code support
- Secure default configuration

## Tasks Sequence

### Pre-installation
- Add Jenkins repository and GPG key
- Install OpenJDK 17
- Install Jenkins package

### Directory Setup
```yaml
- "{{ jenkins_home }}"          # /var/lib/jenkins
- "{{ whanos_root }}"           # /opt/whanos
- "{{ whanos_root }}/jenkins"   # Configuration directory
- "{{ whanos_root }}/images"    # Docker images directory
```

### Configuration
- Copy Jenkins configuration files
- Set up plugin management
- Configure systemd service
- Set proper permissions
- Add Jenkins user to Docker group

### Plugin Management
- Downloads plugin manager
- Installs plugins from plugins.txt
- Uses handlers for idempotent installation

## Environment Variables
```yaml
JAVA_HOME: /usr/lib/jvm/java-17-openjdk-amd64
JENKINS_HOME: {{ jenkins_home }}
CASC_JENKINS_CONFIG: {{ whanos_root }}/jenkins/casc/jenkins-config.yml
JENKINS_PLUGIN_DIR: {{ jenkins_home }}/plugins
JENKINS_ADMIN_PASSWORD: {{ jenkins_admin_password }}
JENKINS_URL: {{ jenkins_url }}
```

## Handlers
- Restart Jenkins service
- Install Jenkins plugins

## Security Considerations
- Custom admin password
- Automated setup wizard disabled
- Proper file permissions
- Docker group membership

## Go back to:

### [Roles Hub](roles-hub.md)
