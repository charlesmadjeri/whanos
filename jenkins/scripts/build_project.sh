#!/bin/bash

DOCKER_TAG=$(echo "${JOB_NAME}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')

REGISTRY_HOST="${REGISTRY_HOST:-registry.digitalocean.com}"

if [ -z "$REGISTRY_NAME" ]; then
    echo "Error: REGISTRY_NAME is required"
    exit 1
fi

if [ -z "$REGISTRY_USERNAME" ] || [ -z "$REGISTRY_TOKEN" ]; then
    echo "Error: REGISTRY_USERNAME and REGISTRY_TOKEN are required"
    exit 1
fi

echo "Logging into registry ${REGISTRY_HOST}..."
echo "$REGISTRY_TOKEN" | docker login "${REGISTRY_HOST}" -u "$REGISTRY_USERNAME" --password-stdin

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

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "Docker build failed"
    exit 1
fi

echo "Tagging and pushing to registry as ${FULL_TAG}..."
docker tag "${DOCKER_TAG}:latest" "${FULL_TAG}"
docker push "${FULL_TAG}"

if [ $? -ne 0 ]; then
    echo "Failed to push image to registry"
    exit 1
fi

# Export variables for other scripts
echo "DOCKER_TAG=${DOCKER_TAG}" > build.env
echo "FULL_TAG=${FULL_TAG}" >> build.env 

if [ -f whanos.yml ]; then
    # Export variables for Jenkins to use
    REPLICAS=$(yq e '.deployment.replicas // 1' whanos.yml)
    MEMORY_LIMITS=$(yq e '.deployment.resources.limits.memory // "128M"' whanos.yml)
    MEMORY_REQUESTS=$(yq e '.deployment.resources.requests.memory // "64M"' whanos.yml)
    PORT=$(yq e '.deployment.ports[0] // ""' whanos.yml)

    # Export for Jenkins environment
    echo "REPLICAS=${REPLICAS}" > whanos.env
    echo "MEMORY_LIMITS=${MEMORY_LIMITS}" >> whanos.env
    echo "MEMORY_REQUESTS=${MEMORY_REQUESTS}" >> whanos.env
    echo "PORT=${PORT}" >> whanos.env
    echo "DOCKER_TAG=${DOCKER_TAG}" >> whanos.env
    echo "FULL_TAG=${FULL_TAG}" >> whanos.env
fi
