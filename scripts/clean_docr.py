#!/usr/bin/env python3
import json
import subprocess
import sys
import time


def run(cmd, check=True):
    print("+", " ".join(cmd), flush=True)
    return subprocess.run(cmd, check=check)


def doctl_json(args):
    out = subprocess.check_output(["doctl", *args, "-o", "json"], text=True)
    out = out.strip()
    if not out:
        return []
    data = json.loads(out)
    if data is None:
        return []
    return data


def main():
    print("=== Deleting tags ===", flush=True)
    for t in doctl_json(["registry", "repository", "list-tags", "whanos"]):
        tag = t.get("tag") or t.get("Tag") or ""
        if not tag:
            continue
        run(["doctl", "registry", "repository", "delete-tag", "whanos", tag, "--force"])

    print("=== Deleting manifests ===", flush=True)
    for m in doctl_json(["registry", "repository", "list-manifests", "whanos"]):
        digest = m.get("digest") or m.get("Digest") or ""
        if not digest:
            continue
        run(
            ["doctl", "registry", "repository", "delete-manifest", "whanos", digest, "--force"],
            check=False,
        )

    print("=== Start GC ===", flush=True)
    run(
        [
            "doctl",
            "registry",
            "garbage-collection",
            "start",
            "--include-untagged-manifests",
            "--force",
        ]
    )

    for i in range(60):
        try:
            active = doctl_json(["registry", "garbage-collection", "get-active"])
        except subprocess.CalledProcessError:
            active = []
        if not active:
            print("GC finished", flush=True)
            break
        print(f"GC active ({i}): {active}", flush=True)
        time.sleep(10)

    print("=== Latest GC ===", flush=True)
    run(["doctl", "registry", "garbage-collection", "list"])
    print("=== Repo state ===", flush=True)
    run(["doctl", "registry", "repository", "list-v2"])
    try:
        tags = doctl_json(["registry", "repository", "list-tags", "whanos"])
        manis = doctl_json(["registry", "repository", "list-manifests", "whanos"])
    except subprocess.CalledProcessError:
        tags, manis = [], []
    print(f"tags={len(tags)} manifests={len(manis)}", flush=True)


if __name__ == "__main__":
    main()
