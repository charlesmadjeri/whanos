#!/usr/bin/env python3
"""Generate Job DSL for a linked Whanos project with JSON-escaped string literals."""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path


def die(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)


def j(s: str) -> str:
    return json.dumps(s)


def main() -> None:
    name = os.environ.get("PROJECT_NAME", "")
    url = os.environ.get("GIT_URL", "")
    branch = os.environ.get("GIT_BRANCH") or "main"
    root = os.environ.get("PROJECT_ROOT") or ""
    creds = os.environ.get("GIT_CREDENTIALS") or ""
    ssh = os.environ.get("GIT_SSH_KEY") or ""
    out = Path(os.environ.get("LINK_DSL_OUT", "linked_project.groovy"))

    if not name:
        die("PROJECT_NAME is required")
    if not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_-]{0,62}", name):
        die("PROJECT_NAME must match [a-zA-Z0-9][a-zA-Z0-9_-]{0,62}")
    if not re.match(r"^(https://|git@)", url):
        die("GIT_URL must start with https:// or git@")
    if not re.fullmatch(r"[a-zA-Z0-9._/-]+", branch):
        die("GIT_BRANCH contains invalid characters")
    if root:
        if not re.fullmatch(r"[a-zA-Z0-9._/-]+", root):
            die("PROJECT_ROOT contains invalid characters")
        if root.startswith("/") or ".." in root.split("/"):
            die("PROJECT_ROOT must be relative and must not contain ..")

    remote_lines = [f"                url({j(url)})"]
    if creds:
        remote_lines.append(f"                credentials({j(creds)})")
    if ssh:
        remote_lines.append(f"                credentials({j(ssh)})")
    remote_block = "\n".join(remote_lines)

    dsl = f"""
job({j("Projects/" + name)}) {{
    disabled(false)
    concurrentBuild(false)
    scm {{
        git {{
            remote {{
{remote_block}
            }}
            branch({j("*/" + branch)})
            extensions {{
                cloneOptions {{
                    timeout(10)
                }}
            }}
        }}
    }}

    triggers {{
        scm('* * * * *')
    }}

    wrappers {{
        credentialsBinding {{
            string('REGISTRY_TOKEN', 'do-registry-token')
            string('REGISTRY_USERNAME', 'do-registry-username')
        }}
        environmentVariables {{
            env('KUBECONFIG', '/var/lib/jenkins/kube/config')
            env('PROJECT_ROOT', {j(root)})
        }}
    }}

    steps {{
        shell('/opt/whanos/jenkins/scripts/run_linked_project.sh')
    }}
}}
"""
    out.write_text(dsl.strip() + "\n", encoding="utf-8")
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
