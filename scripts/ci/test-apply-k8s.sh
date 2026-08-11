#!/usr/bin/env bash
# Generate K8s manifests via apply_k8s.sh with mocked kubectl (no cluster).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

MOCKBIN="${TMP}/bin"
mkdir -p "${MOCKBIN}"
cat > "${MOCKBIN}/kubectl" <<'EOF'
#!/usr/bin/env bash
# Record calls; succeed for apply_k8s control flow.
echo "kubectl $*" >>"${MOCK_LOG}"
case "$1" in
  config) exit 0 ;;
  cluster-info) echo "Kubernetes control plane is running at https://example.invalid"; exit 0 ;;
  apply) exit 0 ;;
  get)
    if [[ "$*" == *nodes* ]]; then
      echo "NAME STATUS"
      echo "node-1 Ready"
      echo "node-2 Ready"
      exit 0
    fi
    if [[ "$*" == *services* ]] || [[ "$*" == *service* ]]; then
      echo "NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S)"
      echo "demo LoadBalancer 10.0.0.1 203.0.113.10 3000:31268/TCP"
      exit 0
    fi
    exit 0
    ;;
  rollout) exit 0 ;;
esac
exit 0
EOF
chmod +x "${MOCKBIN}/kubectl"
export PATH="${MOCKBIN}:${PATH}"
export MOCK_LOG="${TMP}/kubectl.log"
: >"${MOCK_LOG}"

WORKDIR="${TMP}/app"
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

export DOCKER_TAG=demoproject
export FULL_TAG=registry.example.com/whanos/whanos:demoproject
export KUBECONFIG="${TMP}/kubeconfig"
export BUILD_NUMBER=42
cat >"${KUBECONFIG}" <<'EOF'
apiVersion: v1
kind: Config
clusters: []
contexts: []
users: []
EOF

# 1) no whanos.yml → skip
if ! bash "${ROOT}/jenkins/scripts/apply_k8s.sh" | tee "${TMP}/out1" | grep -q "No whanos.yml"; then
  echo "FAIL: expected skip without whanos.yml"
  exit 1
fi
echo "OK  skip without whanos.yml"

# 2) deployment null → skip
printf 'other: true\n' > whanos.yml
# yq: .deployment == null is true when key missing
if ! bash "${ROOT}/jenkins/scripts/apply_k8s.sh" | tee "${TMP}/out2" | grep -qE "No deployment|skipping"; then
  echo "FAIL: expected skip without deployment"
  cat "${TMP}/out2"
  exit 1
fi
echo "OK  skip without deployment"

# 3) full deploy with resources + multi-port
cat > whanos.yml <<'EOF'
deployment:
  replicas: 3
  resources:
    limits:
      cpu: "500m"
      memory: "128M"
    requests:
      cpu: "100m"
      memory: "64M"
  ports:
    - 3000
    - 8080
EOF

bash "${ROOT}/jenkins/scripts/apply_k8s.sh" | tee "${TMP}/out3"
test -f k8s-manifest.yml

yq e '.spec.replicas' k8s-manifest.yml | grep -qx '3'
yq e '.spec.template.spec.containers[0].imagePullPolicy' k8s-manifest.yml | grep -qx 'Always'
yq e '.spec.template.metadata.annotations["whanos/build"]' k8s-manifest.yml | grep -qx '42'
yq e '.spec.template.spec.containers[0].resources.limits.memory' k8s-manifest.yml | grep -qx '128M'
yq e '.spec.template.spec.containers[0].ports | length' k8s-manifest.yml | grep -qx '2'
yq e 'select(.kind == "Service") | .spec.ports | length' k8s-manifest.yml | grep -qx '2'
grep -q 'kubectl apply' "${MOCK_LOG}"

echo "OK  manifest generation + mocked apply"
echo "All apply_k8s tests passed"
