#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOCKER_TAG=$(echo "${JOB_NAME}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')

REGISTRY_HOST="${REGISTRY_HOST:-registry.digitalocean.com}"

if [ -z "${REGISTRY_NAME:-}" ]; then
    echo "Error: REGISTRY_NAME is required"
    exit 1
fi

if [ -z "${REGISTRY_USERNAME:-}" ] || [ -z "${REGISTRY_TOKEN:-}" ]; then
    echo "Error: REGISTRY_USERNAME and REGISTRY_TOKEN are required"
    exit 1
fi

echo "Logging into registry ${REGISTRY_HOST}..."
echo "$REGISTRY_TOKEN" | docker login "${REGISTRY_HOST}" -u "$REGISTRY_USERNAME" --password-stdin

LANGUAGE="$("${SCRIPT_DIR}/detect_language.sh")"
echo "LANGUAGE DETECTED: ${LANGUAGE}"

BASE_IMAGE="${REGISTRY_HOST}/${REGISTRY_NAME}/whanos:whanos-${LANGUAGE}"
FULL_TAG="${REGISTRY_HOST}/${REGISTRY_NAME}/whanos:${DOCKER_TAG}"

if [ -f Dockerfile ]; then
    echo "Building with custom Dockerfile..."
    docker build -t "${DOCKER_TAG}:latest" \
        --build-arg BASE_IMAGE="${BASE_IMAGE}" \
        --no-cache \
        .
else
    echo "Building with standalone Dockerfile..."
    docker build -t "${DOCKER_TAG}:latest" \
        -f "/opt/whanos/images/${LANGUAGE}/Dockerfile.standalone" \
        --no-cache \
        .
fi

echo "Tagging and pushing to registry as ${FULL_TAG}..."
docker tag "${DOCKER_TAG}:latest" "${FULL_TAG}"
docker push "${FULL_TAG}"

echo "DOCKER_TAG=${DOCKER_TAG}" > build.env
echo "FULL_TAG=${FULL_TAG}" >> build.env

if [ -f whanos.yml ]; then
    echo "DOCKER_TAG=${DOCKER_TAG}" > whanos.env
    echo "FULL_TAG=${FULL_TAG}" >> whanos.env
fi
