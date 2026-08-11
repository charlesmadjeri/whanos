#!/bin/bash
# Run from a linked project's Jenkins workspace.
# Honors optional PROJECT_ROOT (relative path to the Whanos app inside the repo).

set -euo pipefail

ROOT="${PROJECT_ROOT:-}"
if [ -z "${ROOT}" ]; then
    ROOT="."
fi

case "${ROOT}" in
    /*|~*)
        echo "PROJECT_ROOT must be a relative path within the workspace"
        exit 1
        ;;
    *..*)
        echo "PROJECT_ROOT must not contain .."
        exit 1
        ;;
esac

cd "${ROOT}"
echo "Working directory: $(pwd)"

echo "Step 1: Building and pushing Docker image..."
/opt/whanos/jenkins/scripts/build_project.sh

echo "Step 2: Processing Kubernetes deployment..."
if [ -f whanos.yml ]; then
    set -a
    # shellcheck disable=SC1091
    . whanos.env
    set +a
    /opt/whanos/jenkins/scripts/apply_k8s.sh
else
    echo "No whanos.yml found, skipping deployment"
fi
