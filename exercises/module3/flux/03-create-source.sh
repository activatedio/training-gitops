#!/usr/bin/env bash
# Module 3 — Flux Step 3: Declare the source
# Tell Flux where the guestbook manifests live. A GitRepository source is
# fetched by the source-controller on an interval. --export writes the CR to a
# file under your cluster path so you can commit it (GitOps all the way down).
#
# Note: the guestbook repo's default branch is "master".
set -euo pipefail

CLUSTER_PATH="${CLUSTER_PATH:-./clusters/my-cluster}"

flux create source git guestbook \
  --url=https://github.com/argoproj/argocd-example-apps.git \
  --branch=master \
  --interval=1m \
  --export > "${CLUSTER_PATH}/guestbook-source.yaml"

echo "Wrote ${CLUSTER_PATH}/guestbook-source.yaml — commit and push it."
