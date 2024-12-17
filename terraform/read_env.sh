#!/bin/bash

# Read .env file and extract required keys
if [ ! -f ./.env ]; then
  echo "Error: .env file not found!"
  exit 1
fi

# Parse the .env file and extract specific variables
VPS_IP=$(grep '^VPS_IP=' ./.env | cut -d '=' -f2 | tr -d '"')
VPS_ROOT_PASSWORD=$(grep '^VPS_ROOT_PASSWORD=' ./.env | cut -d '=' -f2 | tr -d '"')
JENKINS_ADMIN_PASSWORD=$(grep '^JENKINS_ADMIN_PASSWORD=' ./.env | cut -d '=' -f2 | tr -d '"')
JENKINS_URL=$(grep '^JENKINS_URL=' ./.env | cut -d '=' -f2 | tr -d '"')
REGISTRY_USERNAME=$(grep '^REGISTRY_USERNAME=' ./.env | cut -d '=' -f2 | tr -d '"')
REGISTRY_TOKEN=$(grep '^REGISTRY_TOKEN=' ./.env | cut -d '=' -f2 | tr -d '"')
JENKINS_CASC_CFG=$(grep '^JENKINS_CASC_CFG' ./.env | cut -d '=' -f2 | tr -d '"')
JENKINS_DOCKER_REGISTRY=$(grep '^JENKINS_DOCKER_REGISTRY' ./.env | cut -d '=' -f2 | tr -d '"')
JENKINS_SCRIPTS_DIR=$(grep '^JENKINS_SCRIPTS_DIR' ./.env | cut -d '=' -f2 | tr -d '"')
LOCAL_KUBECONFIG_PATH=$(grep '^LOCAL_KUBECONFIG_PATH' ./.env | cut -d '=' -f2 | tr -d '"')
KUBECONFIG_PATH=$(grep '^KUBECONFIG_PATH' ./.env | cut -d '=' -f2 | tr -d '"')


# Return the variables as JSON
cat <<EOF
{
  "vps_ip": "${VPS_IP}",
  "vps_root_password": "${VPS_ROOT_PASSWORD}",
  "jenkins_admin_password": "${JENKINS_ADMIN_PASSWORD}",
  "jenkins_url": "${JENKINS_URL}",
  "registry_username": "${REGISTRY_USERNAME}",
  "registry_token": "${REGISTRY_TOKEN}",
  "jenkins_docker_registry": "${JENKINS_DOCKER_REGISTRY}",
  "jenkins_casc_cfg": "${JENKINS_CASC_CFG}",
  "local_kubeconfig_path": "${LOCAL_KUBECONFIG_PATH}",
  "kubeconfig_path": "${KUBECONFIG_PATH}"
}
EOF
