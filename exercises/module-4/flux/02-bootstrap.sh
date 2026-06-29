#!/usr/bin/env bash
# Module 4 — Flux Step 2: Bootstrap Flux into a Git repo
# Flux bootstraps itself by committing its own controllers into a Git
# repository, then configures the cluster to sync from that repo
# ("Flux manages Flux the GitOps way"). This brings up the toolkit
# controllers in the flux-system namespace: source-controller,
# kustomize-controller, helm-controller, and notification-controller.
#
# EDIT THESE before running:
set -euo pipefail

export GITHUB_USER="${GITHUB_USER:-<your-github-username>}"
export GITHUB_TOKEN="${GITHUB_TOKEN:-<your-pat-with-repo-scope>}"
REPO="${REPO:-fleet-infra}"
BRANCH="${BRANCH:-main}"
CLUSTER_PATH="${CLUSTER_PATH:-clusters/my-cluster}"

flux bootstrap github \
  --owner="$GITHUB_USER" \
  --repository="$REPO" \
  --branch="$BRANCH" \
  --path="$CLUSTER_PATH" \
  --personal
