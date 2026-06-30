#!/usr/bin/env bash
# Module 3 — ArgoCD: Create the "example" project and deploy podinfo
# The template ships the default/roots/cluster-addons projects but no workloads.
# Here we add a dedicated `example` project the GitOps way:
#   1. projects/example.yaml — the `example` AppProject + an `example-root`
#      Application (in that project) that syncs roots/example/
#   2. roots/example/podinfo.yaml — podinfo (project: example), from its Helm repo
# The `root` Application applies projects/example.yaml; example-root then applies
# podinfo. Because the ingress controller is already up (03), podinfo ships with
# its chart ingress enabled and lands at http://podinfo.localtest.me.
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
SRC="$(cd "$(dirname "$0")/../manifests" && pwd)"

cd "$GITOPS_DIR"
REPO_URL="$(git remote get-url origin)"

# 1. The example project + its root (point the root's generator at your repo).
cp "$SRC/projects/example.yaml" projects/example.yaml
perl -pi -e "s{__GIT_REPO_URL__}{${REPO_URL}}g" projects/example.yaml

# 2. The podinfo child Application (references the podinfo Helm repo — no repo URL to set).
mkdir -p roots/example
cp "$SRC/roots/example/podinfo.yaml" roots/example/podinfo.yaml

git add projects/example.yaml roots/example/podinfo.yaml
git commit -m "add example project + podinfo" && git push

echo
echo "✓ example project + podinfo committed. Watch root -> example-root -> podinfo;"
echo "  once synced, open http://podinfo.localtest.me."
