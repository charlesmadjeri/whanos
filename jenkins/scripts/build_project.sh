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

if [ -f Dockerfile ]; then
    echo "Building with custom Dockerfile..."
    docker build -t "${DOCKER_TAG}:latest" --build-arg BASE_IMAGE="registry.digitalocean.com/whanos-container-registry/whanos:${LANGUAGE}-base" .
else
    echo "Building with standalone Dockerfile..."
    docker build -t "${DOCKER_TAG}:latest" -f "/opt/whanos/images/${LANGUAGE}/Dockerfile.standalone" .
fi

echo "Tagging and pushing to DigitalOcean registry..."
docker tag "${DOCKER_TAG}:latest" "registry.digitalocean.com/whanos-container-registry/whanos:${DOCKER_TAG}"
docker push "registry.digitalocean.com/whanos-container-registry/whanos:${DOCKER_TAG}"

if [ -f whanos.yml ]; then
    echo "Applying Kubernetes configuration..."
    kubectl apply -f whanos.yml
fi 