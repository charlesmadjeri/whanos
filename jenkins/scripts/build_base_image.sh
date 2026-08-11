#!/bin/bash

set -euo pipefail

LANGUAGE=$1

if [ -z "$LANGUAGE" ]; then
    echo "Error: Language parameter is required"
    exit 1
fi

REGISTRY_HOST="${REGISTRY_HOST:-registry.digitalocean.com}"

if [ -z "$REGISTRY_NAME" ]; then
    echo "Error: REGISTRY_NAME is required"
    exit 1
fi

if [ -z "$REGISTRY_USERNAME" ] || [ -z "$REGISTRY_TOKEN" ]; then
    echo "Error: REGISTRY_USERNAME and REGISTRY_TOKEN are required"
    exit 1
fi

IMAGE_REF="${REGISTRY_HOST}/${REGISTRY_NAME}/whanos:whanos-${LANGUAGE}"

echo "Logging into registry ${REGISTRY_HOST}..."
echo "$REGISTRY_TOKEN" | docker login "${REGISTRY_HOST}" -u "$REGISTRY_USERNAME" --password-stdin

cd "/opt/whanos/images/${LANGUAGE}"

echo "Building base image..."
docker build --no-cache -t "whanos-${LANGUAGE}:latest" - < Dockerfile.base

echo "Tagging as ${IMAGE_REF}..."
docker tag "whanos-${LANGUAGE}:latest" "${IMAGE_REF}"

echo "Pushing ${IMAGE_REF}..."
for attempt in 1 2 3; do
    if docker push "${IMAGE_REF}"; then
        echo "Push succeeded"
        exit 0
    fi
    echo "Push attempt ${attempt} failed; waiting..."
    sleep $((attempt * 15))
done

echo "Error: failed to push ${IMAGE_REF}"
exit 1
