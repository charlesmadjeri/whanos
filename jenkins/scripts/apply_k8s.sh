#!/bin/bash
set -euo pipefail

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

export DOCKER_TAG FULL_TAG

echo "Using kubeconfig at: ${KUBECONFIG}"
if [ ! -f "${KUBECONFIG}" ]; then
    echo "Kubeconfig file not found!"
    exit 1
fi

# DigitalOcean kubeconfigs call `doctl` for tokens; reuse the DO API token
# already bound as REGISTRY_TOKEN for registry login.
if [ -z "${DIGITALOCEAN_ACCESS_TOKEN:-}" ] && [ -n "${REGISTRY_TOKEN:-}" ]; then
    export DIGITALOCEAN_ACCESS_TOKEN="${REGISTRY_TOKEN}"
fi

REPLICAS=$(yq e '.deployment.replicas // 1' whanos.yml)
if ! [[ "${REPLICAS}" =~ ^[0-9]+$ ]]; then
    echo "Invalid deployment.replicas in whanos.yml (must be a non-negative integer): ${REPLICAS}"
    exit 1
fi
export REPLICAS

PORT_COUNT=$(yq e '.deployment.ports // [] | length' whanos.yml)

echo "Creating Kubernetes manifest..."

# Mutable registry tags (…:projectname) need Always + a changing annotation,
# otherwise apply is a no-op and nodes keep a cached digest (IfNotPresent).
export WHANOS_BUILD_ID="${BUILD_NUMBER:-${BUILD_ID:-$(date +%s)}}"

# Deployment (always). REPLICAS is validated as ^[0-9]+$ above, so embedding
# the integer literal is safe and avoids yq env/tonumber quirks across versions.
yq -n "
.apiVersion = \"apps/v1\" |
.kind = \"Deployment\" |
.metadata.name = strenv(DOCKER_TAG) |
.metadata.labels.app = strenv(DOCKER_TAG) |
.spec.replicas = ${REPLICAS} |
.spec.selector.matchLabels.app = strenv(DOCKER_TAG) |
.spec.template.metadata.labels.app = strenv(DOCKER_TAG) |
.spec.template.metadata.annotations.\"whanos/build\" = strenv(WHANOS_BUILD_ID) |
.spec.template.spec.containers[0].name = strenv(DOCKER_TAG) |
.spec.template.spec.containers[0].image = strenv(FULL_TAG) |
.spec.template.spec.containers[0].imagePullPolicy = \"Always\"
" > k8s-manifest.yml

if [ "$(yq e '.deployment | has("resources")' whanos.yml)" = "true" ]; then
    yq e -i '.spec.template.spec.containers[0].resources = load("whanos.yml").deployment.resources' k8s-manifest.yml
fi

if [ "${PORT_COUNT}" -gt 0 ]; then
    yq e -i '.spec.template.spec.containers[0].ports = (load("whanos.yml").deployment.ports | map({"containerPort": .}))' k8s-manifest.yml

    {
        echo "---"
        yq -n '
        .apiVersion = "v1" |
        .kind = "Service" |
        .metadata.name = strenv(DOCKER_TAG) |
        .spec.type = "LoadBalancer" |
        .spec.selector.app = strenv(DOCKER_TAG) |
        .spec.ports = (load("whanos.yml").deployment.ports | map({"port": ., "targetPort": ., "protocol": "TCP"}))
        '
    } >> k8s-manifest.yml
fi

echo "Generated manifest:"
cat k8s-manifest.yml

echo "kubectl context: $(kubectl config current-context 2>/dev/null || echo unknown)"

if ! kubectl cluster-info; then
    echo "Failed to connect to cluster"
    exit 1
fi

if ! kubectl apply -f k8s-manifest.yml; then
    echo "Failed to apply manifest"
    exit 1
fi

echo "Manifest applied successfully"
echo "Available nodes:"
kubectl get nodes || true

echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/"${DOCKER_TAG}" --timeout=120s

if [ "${PORT_COUNT}" -gt 0 ]; then
    echo "Checking service status..."
    kubectl get services "${DOCKER_TAG}"

    echo "Waiting for external IP..."
    for i in {1..30}; do
        EXTERNAL_IP=$(kubectl get service "${DOCKER_TAG}" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [ -n "$EXTERNAL_IP" ]; then
            for port in $(yq e '.deployment.ports[]' whanos.yml); do
                echo "Service available at: http://${EXTERNAL_IP}:${port}"
            done
            break
        fi
        echo "Waiting for external IP... (attempt $i/30)"
        sleep 10
    done
fi
