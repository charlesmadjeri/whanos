#!/usr/bin/env bash
# Terraform external data source: stdin JSON {"path":"..."} → {"fingerprint":"aa:bb:..."}
set -euo pipefail
eval "$(python3 -c 'import json,sys,shlex; q=json.load(sys.stdin); print("KEY_PATH="+shlex.quote(q["path"]))')"
fp="$(ssh-keygen -lf "$KEY_PATH" -E md5 | awk '{print $2}' | sed 's/^MD5://')"
python3 -c 'import json,sys; print(json.dumps({"fingerprint": sys.argv[1]}))' "$fp"
