#!/bin/bash

if [ ! -f whanos.yml ]; then
    echo "No whanos.yml found, skipping Kubernetes deployment"
    exit 0
fi

if [ "$(yq e '.deployment == null' whanos.yml)" = "true" ]; then
    echo "No deployment property in whanos.yml, skipping Kubernetes deployment"
    exit 0
fi

for var in DOCKER_TAG FULL_TAG; do
    if [ -z "${!var}" ]; then
        echo "Required variable $var is not set"
        exit 1
    fi
done

TEMPLATE_PATH="/opt/whanos/jenkins/templates/k8s-manifest.yml.template"
if [ ! -f "${TEMPLATE_PATH}" ]; then
    echo "Template file not found at ${TEMPLATE_PATH}"
    exit 1
fi

echo "Using kubeconfig at: ${KUBECONFIG}"
if [ ! -f "${KUBECONFIG}" ]; then
    echo "Kubeconfig file not found!"
    exit 1
fi

REPLICAS=$(yq e '.deployment.replicas // 1' whanos.yml)
# Keep single-port behavior for now; multi-port handled in a follow-up.
PORT=$(yq e '.deployment.ports[0] // ""' whanos.yml)

export DOCKER_TAG FULL_TAG REPLICAS PORT

echo "Creating Kubernetes manifest..."
envsubst < "${TEMPLATE_PATH}" > k8s-manifest.yml

# Apply Kubernetes resources as-is when present; omit when unset (subject default).
if [ "$(yq e '.deployment | has("resources")' whanos.yml)" = "true" ]; then
    yq e -i '.spec.template.spec.containers[0].resources = load("whanos.yml").deployment.resources' k8s-manifest.yml
else
    yq e -i 'del(.spec.template.spec.containers[0].resources)' k8s-manifest.yml
fi

# Drop empty container port when whanos.yml defines none.
if [ -z "${PORT}" ] || [ "${PORT}" = "null" ]; then
    yq e -i 'del(.spec.template.spec.containers[0].ports)' k8s-manifest.yml
    yq e -i 'select(document_index == 0)' k8s-manifest.yml > k8s-manifest.tmp.yml
    mv k8s-manifest.tmp.yml k8s-manifest.yml
fi

echo "Kubeconfig contents:"
kubectl config view

sleep 2

if ! kubectl cluster-info; then
    echo "Failed to connect to cluster. Retrying with validation disabled..."
    if ! kubectl apply -f k8s-manifest.yml --validate=false; then
        echo "Failed to apply manifest"
        echo "Manifest contents:"
        cat k8s-manifest.yml
        exit 1
    fi
else
    if ! kubectl apply -f k8s-manifest.yml; then
        echo "Failed to apply manifest"
        echo "Manifest contents:"
        cat k8s-manifest.yml
        exit 1
    fi
fi

echo "Manifest applied successfully"
echo "Current kubectl context:"
kubectl config current-context || true
echo "Available nodes:"
kubectl get nodes || true

echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/${DOCKER_TAG} --timeout=120s

if [ -n "${PORT}" ] && [ "${PORT}" != "null" ]; then
    echo "Checking service status..."
    kubectl get services ${DOCKER_TAG}

    echo "Waiting for external IP..."
    for i in {1..30}; do
        EXTERNAL_IP=$(kubectl get service ${DOCKER_TAG} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [ -n "$EXTERNAL_IP" ]; then
            echo "Service available at: http://${EXTERNAL_IP}:${PORT}"
            break
        fi
        echo "Waiting for external IP... (attempt $i/30)"
        sleep 10
    done
fi
