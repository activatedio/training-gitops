#!/usr/bin/env bash
# Module 4 — Flux Step 3: Declare the source
# Tell Flux where the chart lives. A HelmRepository source points the
# source-controller at podinfo's Helm repository (the same one ArgoCD pulled
# from); it polls the repo index on an interval. --export writes the CR to a file
# under your cluster path so you can commit it (GitOps all the way down).
set -euo pipefail

CLUSTER_PATH="${CLUSTER_PATH:-./clusters/my-cluster}"

flux create source helm podinfo \
  --url=https://stefanprodan.github.io/podinfo \
  --interval=1m \
  --export > "${CLUSTER_PATH}/podinfo-source.yaml"

echo "Wrote ${CLUSTER_PATH}/podinfo-source.yaml — commit and push it."
