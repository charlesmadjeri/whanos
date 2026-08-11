#!/bin/bash
# Detect a single Whanos language in the current directory.
# Prints the language name on stdout.
# Exit 0 = ok, 2 = multiple criteria, 3 = none.

set -euo pipefail

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
    echo "No valid Whanos project structure detected" >&2
    exit 3
fi

COUNT=0
[ -f Makefile ] && COUNT=$((COUNT + 1))
[ -f app/pom.xml ] && COUNT=$((COUNT + 1))
[ -f package.json ] && COUNT=$((COUNT + 1))
[ -f requirements.txt ] && COUNT=$((COUNT + 1))
[ -f app/main.bf ] && COUNT=$((COUNT + 1))

if [ "${COUNT}" -gt 1 ]; then
    echo "Multiple language detection criteria found" >&2
    exit 2
fi

echo "${LANGUAGE}"
