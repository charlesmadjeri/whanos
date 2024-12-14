#!/bin/bash

LANGUAGE=$1

if [ -z "$LANGUAGE" ]; then
    echo "Error: Language parameter is required"
    exit 1
fi

echo "Logging into DigitalOcean registry..."
echo "$REGISTRY_TOKEN" | docker login registry.digitalocean.com -u "$REGISTRY_USERNAME" --password-stdin

cd /opt/whanos/images/${LANGUAGE}

echo "Building base image..."
docker build -t whanos-${LANGUAGE}-base:latest - < Dockerfile.base

echo "Tagging base image..."
docker tag whanos-${LANGUAGE}-base:latest registry.digitalocean.com/whanos-container-registry/whanos:${LANGUAGE}-base

echo "Pushing base image..."
docker push registry.digitalocean.com/whanos-container-registry/whanos:${LANGUAGE}-base