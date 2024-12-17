#!/bin/bash

# Read .env file and extract required keys
if [ ! -f ./.env ]; then
  echo "Error: .env file not found!"
  exit 1
fi

# Parse the .env file and extract specific variables
VPS_IP=$(grep '^VPS_IP=' ./.env | cut -d '=' -f2 | tr -d '"')
ROOT_PASSWORD=$(grep '^ROOT_PASSWORD=' ./.env | cut -d '=' -f2 | tr -d '"')
JENKINS_ADMIN_PASSWORD=$(grep '^JENKINS_ADMIN_PASSWORD=' ./.env | cut -d '=' -f2 | tr -d '"')
JENKINS_URL=$(grep '^JENKINS_URL=' ./.env | cut -d '=' -f2 | tr -d '"')
REGISTRY_USERNAME=$(grep '^REGISTRY_USERNAME=' ./.env | cut -d '=' -f2 | tr -d '"')
REGISTRY_TOKEN=$(grep '^REGISTRY_TOKEN=' ./.env | cut -d '=' -f2 | tr -d '"')

# Return the variables as JSON
cat <<EOF
{
  "vps_ip": "${VPS_IP}",
  "root_password": "${ROOT_PASSWORD}",
  "jenkins_admin_password": "${JENKINS_ADMIN_PASSWORD}",
  "jenkins_url": "${JENKINS_URL}",
  "registry_username": "${REGISTRY_USERNAME}",
  "registry_token": "${REGISTRY_TOKEN}"
}
EOF
