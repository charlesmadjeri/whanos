#!/bin/bash

if [ ! -f whanos.yml ]; then
    echo "No whanos.yml found, skipping Kubernetes deployment"
    exit 0
fi

# Check required variables
for var in REPLICAS MEMORY_LIMITS MEMORY_REQUESTS PORT DOCKER_TAG FULL_TAG; do
    if [ -z "${!var}" ]; then
        echo "Required variable $var is not set"
        exit 1
    fi
done

# Create manifest from template
TEMPLATE_PATH="/opt/whanos/jenkins/templates/k8s-manifest.yml.template"
if [ ! -f "${TEMPLATE_PATH}" ]; then
    echo "Template file not found at ${TEMPLATE_PATH}"
    exit 1
fi

# Debug kubeconfig
echo "Using kubeconfig at: ${KUBECONFIG}"
if [ ! -f "${KUBECONFIG}" ]; then
    echo "Kubeconfig file not found!"
    exit 1
fi

# Create manifest from template first
echo "Creating Kubernetes manifest..."
envsubst < "${TEMPLATE_PATH}" > k8s-manifest.yml

echo "Kubeconfig contents:"
kubectl config view

# Add cluster host to /etc/hosts if needed
# CLUSTER_HOST=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}' | sed 's|https://||' | cut -d: -f1)
# if [ ! -z "${CLUSTER_HOST}" ]; then
#     echo "Adding cluster host to /etc/hosts..."
#     # Try to resolve using Google DNS directly
#     CLUSTER_IP=$(dig @8.8.8.8 +short "${CLUSTER_HOST}")
    
#     if [ ! -z "${CLUSTER_IP}" ]; then
#         echo "Resolved ${CLUSTER_HOST} to ${CLUSTER_IP}"
#         echo "${CLUSTER_IP} ${CLUSTER_HOST}" | sudo tee -a /etc/hosts
#         # Also add to Docker's DNS
#         echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
#     fi
# fi

# Add a small delay to allow DNS propagation
sleep 2

# Test connection before proceeding
if ! kubectl cluster-info; then
    echo "Failed to connect to cluster. Retrying with validation disabled..."
    kubectl apply -f k8s-manifest.yml --validate=false
else
    kubectl apply -f k8s-manifest.yml
fi

# Debug information
echo "Current kubectl context:"
kubectl config current-context || true
echo "Cluster info:"
kubectl cluster-info dump
echo "Available nodes:"
kubectl get nodes || true

if [ $? -eq 0 ]; then
    echo "Manifest applied successfully"
    echo "Checking deployment status..."
    echo "Waiting for deployment to be ready..."
    kubectl rollout status deployment/${DOCKER_TAG} --timeout=120s
    
    echo "Checking service status..."
    kubectl get services ${DOCKER_TAG}
    
    echo "Waiting for external IP..."
    for i in {1..30}; do
        EXTERNAL_IP=$(kubectl get service ${DOCKER_TAG} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [ ! -z "$EXTERNAL_IP" ]; then
            echo "Service available at: http://${EXTERNAL_IP}:3000"
            break
        fi
        echo "Waiting for external IP... (attempt $i/30)"
        sleep 10
    done
else
    echo "Failed to apply manifest"
    echo "Manifest contents:"
    cat k8s-manifest.yml
    exit 1
fi