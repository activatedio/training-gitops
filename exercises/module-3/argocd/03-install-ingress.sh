#!/usr/bin/env bash
# Module 3 — ArgoCD: Install an ingress controller (cluster-addon), in-cluster only
# We install ingress BEFORE the workload so podinfo can come up with its own
# ingress (next script). Unlike sealed-secrets, ingress-nginx uses a per-cluster
# git generator — it only installs where an opt-in config exists, and we provide
# one just for the local "in-cluster" cluster. This also exposes the ArgoCD UI
# via an nginx SSL-passthrough Ingress.
#
# PREREQUISITE: your kind cluster must map host 80/443 + label a node
# ingress-ready. The Module 1 config does this; if your cluster predates it,
# recreate it (kind create cluster --config exercises/module-1/kind-config.yaml)
# and re-run 01-bootstrap-install.sh first.
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
SRC="$(cd "$(dirname "$0")/../manifests" && pwd)"

cd "$GITOPS_DIR"
REPO_URL="$(git remote get-url origin)"

# 1. ingress-nginx ApplicationSet (git generator) + the in-cluster opt-in config.
mkdir -p roots/cluster-addons/cluster-configs/in-cluster
cp "$SRC/roots/cluster-addons/ingress-nginx.yaml" roots/cluster-addons/ingress-nginx.yaml
cp "$SRC/roots/cluster-addons/cluster-configs/in-cluster/ingress-nginx.yaml" \
   roots/cluster-addons/cluster-configs/in-cluster/ingress-nginx.yaml
# Point the generator at your repo (the chart still comes from the Helm repo).
perl -pi -e "s{__GIT_REPO_URL__}{${REPO_URL}}g" roots/cluster-addons/ingress-nginx.yaml

# 2. ArgoCD UI Ingress (SSL passthrough), applied via the cluster-resources ApplicationSet.
mkdir -p cluster-resources/in-cluster
cp "$SRC/cluster-resources/in-cluster/argocd-server-ingress.yaml" cluster-resources/in-cluster/

git add roots/cluster-addons/ingress-nginx.yaml roots/cluster-addons/cluster-configs \
        cluster-resources/in-cluster/argocd-server-ingress.yaml
git commit -m "install ingress-nginx (in-cluster) + expose argocd" && git push

echo
echo "✓ Ingress installed. Once synced: ArgoCD at https://argocd.localtest.me (accept the self-signed cert)."
echo "  Next: ./04-add-example-root.sh deploys podinfo at http://podinfo.localtest.me."
