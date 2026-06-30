#!/usr/bin/env bash
# Module 3 — ArgoCD: Build the "example" root (app-of-apps) from scratch
# The template ships the default/roots/cluster-addons projects and a live
# cluster-addons-root, but no workloads. Here we stand up a NEW root the GitOps
# way:
#   1. add a child Application under roots/example/ (podinfo, pulled from its Helm repo)
#   2. add an `example-root` Application to projects/roots.yaml pointing at roots/example/
# The `root` Application applies example-root, example-root applies podinfo — app-of-apps.
# Because the ingress controller is already up (03), podinfo ships with its chart
# ingress enabled and lands at http://podinfo.localtest.me.
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
# The podinfo child Application in this exercises checkout.
SRC="$(cd "$(dirname "$0")/../manifests/roots/example" && pwd)"

cd "$GITOPS_DIR"
REPO_URL="$(git remote get-url origin)"

# 1. The child Application (references the podinfo Helm repo — no repo URL to set).
mkdir -p roots/example
cp "$SRC/podinfo.yaml" roots/example/podinfo.yaml

# 2. The example-root, appended to projects/roots.yaml (idempotent).
if ! grep -q 'name: example-root' projects/roots.yaml; then
  cat >> projects/roots.yaml <<YAML
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: example-root
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: roots
  source:
    repoURL: ${REPO_URL}
    path: roots/example
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

git add roots/example/podinfo.yaml projects/roots.yaml
git commit -m "add example root + podinfo" && git push

echo
echo "✓ example-root + podinfo committed. Watch root -> example-root -> podinfo;"
echo "  once synced, open http://podinfo.localtest.me."
