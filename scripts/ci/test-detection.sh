#!/usr/bin/env bash
# Offline detection checks mirroring jenkins/scripts/build_project.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0

detect() {
  local dir="$1"
  (
    cd "$dir"
    if [ -f Makefile ]; then LANGUAGE=c
    elif [ -f app/pom.xml ]; then LANGUAGE=java
    elif [ -f package.json ]; then LANGUAGE=javascript
    elif [ -f requirements.txt ]; then LANGUAGE=python
    elif [ -f app/main.bf ]; then LANGUAGE=befunge
    else
      echo "NONE"
      return 3
    fi
    COUNT=0
    [ -f Makefile ] && COUNT=$((COUNT + 1))
    [ -f app/pom.xml ] && COUNT=$((COUNT + 1))
    [ -f package.json ] && COUNT=$((COUNT + 1))
    [ -f requirements.txt ] && COUNT=$((COUNT + 1))
    [ -f app/main.bf ] && COUNT=$((COUNT + 1))
    if [ "${COUNT}" -gt 1 ]; then
      echo "MULTI"
      return 2
    fi
    echo "${LANGUAGE}"
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

# Example apps
EX="${ROOT}/docs/example_apps/whanos_example_apps"
assert_eq "c-hello-world" "$(detect "${EX}/c-hello-world")" "c"
assert_eq "java-hello-world" "$(detect "${EX}/java-hello-world")" "java"
assert_eq "js-hello-world" "$(detect "${EX}/js-hello-world")" "javascript"
assert_eq "python-hello-world" "$(detect "${EX}/python-hello-world")" "python"
assert_eq "befunge-hello-world" "$(detect "${EX}/befunge-hello-world")" "befunge"
assert_eq "ts-hello-world" "$(detect "${EX}/ts-hello-world")" "javascript"

# Edge cases
mkdir -p "${TMP}/multi" "${TMP}/none" "${TMP}/none/app"
touch "${TMP}/multi/Makefile" "${TMP}/multi/package.json"
touch "${TMP}/none/README"
assert_eq "multi-criteria" "$(detect "${TMP}/multi" || true)" "MULTI"
assert_eq "no-criteria" "$(detect "${TMP}/none" || true)" "NONE"

if [ "${FAIL}" -ne 0 ]; then
  echo "detection tests failed"
  exit 1
fi
echo "All detection tests passed"
