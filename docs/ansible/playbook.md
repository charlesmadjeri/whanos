# Playbook Structure

## Main Playbook
```yaml
---
- name: Setup Whanos on Debian VPS
  hosts: whanos
  become: yes
  roles:
    - ufw
    - docker
    - jenkins
    - nginx
```

## Role Execution Order

1. **UFW**
   - Initial security setup
   - Port configuration
   - Firewall rules

2. **Docker**
   - Container runtime
   - System requirements
   - Service configuration

3. **Jenkins**
   - CI/CD server
   - Plugin management
   - Docker integration

4. **Nginx**
   - Reverse proxy
   - HTTP configuration
   - Service exposure

## Variables
Located in `group_vars/all.yml`:
```yaml
vps_ip: ""                  # VPS IP address
vps_root_password: ""       # Root password
jenkins_admin_password: ""  # Jenkins admin password
jenkins_url: ""             # Jenkins URL
jenkins_home: ""            # Jenkins home directory
whanos_root: ""             # Whanos root directory
```

## Inventory
```yaml
all:
  hosts:
    whanos:
      ansible_host: "{{ vps_ip }}"
      ansible_user: root
      ansible_password: "{{ vps_root_password }}"
      ansible_become: yes
```

## Go back to:

### [Ansible Hub](ansible-hub.md)