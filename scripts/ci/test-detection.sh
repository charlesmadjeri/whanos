#!/usr/bin/env bash
# Detection checks via the real jenkins/scripts/detect_language.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DETECT="${ROOT}/jenkins/scripts/detect_language.sh"
chmod +x "${DETECT}"
FAIL=0

run_detect() {
  local dir="$1"
  (
    cd "$dir"
    set +e
    out="$("${DETECT}" 2>/dev/null)"
    rc=$?
    set -e
    case "${rc}" in
      0) echo "${out}" ;;
      2) echo "MULTI" ;;
      3) echo "NONE" ;;
      *) echo "ERR${rc}" ;;
    esac
  )
}

assert_eq() {
  local name="$1" got="$2" want="$3"
  if [ "${got}" = "${want}" ]; then
    echo "OK  ${name}: ${got}"
  else
    echo "FAIL ${name}: got='${got}' want='${want}'"
    FAIL=1
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

EX="${ROOT}/docs/example_apps/whanos_example_apps"
assert_eq "c-hello-world" "$(run_detect "${EX}/c-hello-world")" "c"
assert_eq "java-hello-world" "$(run_detect "${EX}/java-hello-world")" "java"
assert_eq "js-hello-world" "$(run_detect "${EX}/js-hello-world")" "javascript"
assert_eq "python-hello-world" "$(run_detect "${EX}/python-hello-world")" "python"
assert_eq "befunge-hello-world" "$(run_detect "${EX}/befunge-hello-world")" "befunge"
assert_eq "ts-hello-world" "$(run_detect "${EX}/ts-hello-world")" "javascript"

mkdir -p "${TMP}/multi" "${TMP}/none"
touch "${TMP}/multi/Makefile" "${TMP}/multi/package.json"
touch "${TMP}/none/README"
assert_eq "multi-criteria" "$(run_detect "${TMP}/multi")" "MULTI"
assert_eq "no-criteria" "$(run_detect "${TMP}/none")" "NONE"

if [ "${FAIL}" -ne 0 ]; then
  echo "detection tests failed"
  exit 1
fi
echo "All detection tests passed"
