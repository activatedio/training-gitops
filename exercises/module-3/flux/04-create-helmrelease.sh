#!/usr/bin/env bash
# Module 3 — Flux Step 4: Declare the HelmRelease
# Hand the chart to the helm-controller. A HelmRelease names the chart in the
# HelmRepository source (podinfo, pinned to a version) and the helm-controller
# installs and upgrades the actual Helm release to match. Then commit both files
# — because Flux is already syncing this repo, the deploy happens the moment your
# commit lands.
set -euo pipefail

CLUSTER_PATH="${CLUSTER_PATH:-./clusters/my-cluster}"

flux create helmrelease podinfo \
  --source=HelmRepository/podinfo \
  --chart=podinfo \
  --chart-version=6.14.0 \
  --target-namespace=podinfo \
  --create-target-namespace=true \
  --interval=5m \
  --export > "${CLUSTER_PATH}/podinfo-helmrelease.yaml"

# Commit and push — Flux picks it up and deploys podinfo automatically.
git add -A && git commit -m "deploy podinfo (helm)" && git push
