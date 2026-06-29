#!/usr/bin/env bash
# Module 3 — ArgoCD: Build the "dev" root (app-of-apps) from scratch
# The template ships the default/roots/cluster-addons projects and a live
# cluster-addons-root, but no workloads. Here we stand up a NEW root the GitOps
# way:
#   1. add a child Application under roots/dev/ (podinfo, pulled from its Helm repo)
#   2. add a `dev-root` Application to projects/roots.yaml pointing at roots/dev/
# The `root` Application applies dev-root, dev-root applies podinfo — app-of-apps.
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
# The podinfo child Application in this exercises checkout.
SRC="$(cd "$(dirname "$0")/../manifests/roots/dev" && pwd)"

cd "$GITOPS_DIR"
REPO_URL="$(git remote get-url origin)"

# 1. The child Application (references the podinfo Helm repo — no repo URL to set).
mkdir -p roots/dev
cp "$SRC/podinfo.yaml" roots/dev/podinfo.yaml

# 2. The dev-root, appended to projects/roots.yaml (idempotent).
if ! grep -q 'name: dev-root' projects/roots.yaml; then
  cat >> projects/roots.yaml <<YAML
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dev-root
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: roots
  source:
    repoURL: ${REPO_URL}
    path: roots/dev
    targetRevision: HEAD
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - ServerSideApply=true
      - CreateNamespace=true
YAML
fi

git add roots/dev/podinfo.yaml projects/roots.yaml
git commit -m "add dev root + podinfo" && git push

echo
echo "✓ dev-root + podinfo committed. In the UI watch: root -> dev-root -> podinfo (namespace 'podinfo')."
