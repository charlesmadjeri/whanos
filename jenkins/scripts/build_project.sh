#!/bin/bash

echo "WORKSPACE: ${WORKSPACE}"

DOCKER_TAG=$(echo "${JOB_NAME}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
echo "DOCKER_TAG: ${DOCKER_TAG}"

echo "Logging into DigitalOcean registry..."
echo "$REGISTRY_TOKEN" | docker login registry.digitalocean.com -u "$REGISTRY_USERNAME" --password-stdin

if [ -f Makefile ]; then
    LANGUAGE="c"
elif [ -f app/pom.xml ]; then
    LANGUAGE="java"
elif [ -f package.json ]; then
    LANGUAGE="javascript"
elif [ -f requirements.txt ]; then
    LANGUAGE="python"
elif [ -f app/main.bf ]; then
    LANGUAGE="befunge"
else
    echo "No valid Whanos project structure detected"
    echo 'Files found: '
    tree
    exit 1
fi

echo "LANGUAGE DETECTED: ${LANGUAGE}"

COUNT=0
[ -f Makefile ] && COUNT=$((COUNT+1))
[ -f app/pom.xml ] && COUNT=$((COUNT+1))
[ -f package.json ] && COUNT=$((COUNT+1))
[ -f requirements.txt ] && COUNT=$((COUNT+1))
[ -f app/main.bf ] && COUNT=$((COUNT+1))

if [ ${COUNT} -gt 1 ]; then
    echo "Multiple language detection criteria found"
    exit 1
fi

BASE_IMAGE="registry.digitalocean.com/whanos-container-registry/whanos-${LANGUAGE}"

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

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "Docker build failed"
    exit 1
fi

echo "Tagging and pushing to DigitalOcean registry..."
FULL_TAG="registry.digitalocean.com/whanos-container-registry/${DOCKER_TAG}"
docker tag "${DOCKER_TAG}:latest" "${FULL_TAG}:latest"
docker push "${FULL_TAG}:latest"

if [ $? -ne 0 ]; then
    echo "Failed to push image to registry"
    exit 1
fi

if [ -f whanos.yml ]; then
    echo "Applying Kubernetes configuration..."
    if ! command -v kubectl &> /dev/null; then
        echo "kubectl not found, skipping Kubernetes deployment"
        exit 0
    fi
    kubectl apply -f whanos.yml
fi 