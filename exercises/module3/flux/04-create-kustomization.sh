#!/usr/bin/env bash
# Module 3 — Flux Step 4: Declare the Kustomization
# Point the kustomize-controller at the path inside that source. The
# Kustomization applies the manifests and, with --prune, removes anything you
# later delete from Git. Then commit both files — because Flux is already
# syncing this repo, the deploy happens the moment your commit lands.
set -euo pipefail

CLUSTER_PATH="${CLUSTER_PATH:-./clusters/my-cluster}"

flux create kustomization guestbook \
  --source=GitRepository/guestbook \
  --path="./guestbook" \
  --prune=true \
  --target-namespace=guestbook \
  --interval=5m \
  --health-check="Deployment/guestbook-ui.guestbook" \
  --export > "${CLUSTER_PATH}/guestbook-kustomization.yaml"

# Commit and push — Flux picks it up and deploys the guestbook automatically.
git add -A && git commit -m "deploy guestbook" && git push
