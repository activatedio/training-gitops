#!/usr/bin/env bash
# Module 3 — ArgoCD Step 1+2: Bootstrap a self-managing ArgoCD from a template
#
# Instead of piping the upstream install manifest and driving ArgoCD with the
# `argocd` CLI, we clone a bootstrap template and let it install an ArgoCD that
# manages ITSELF from Git. After this, every change is a commit you review in
# the UI — not an imperative command.
#
# What `make install` does (each phase is also its own make target):
#   render the repo URL + version into the manifests, create the namespace and a
#   repo-access secret from your token, server-side-apply the ArgoCD install,
#   wait for it, then apply the self-managing `root` + `argo-cd` Applications.
#
# EDIT THESE before running:
set -euo pipefail

GIT_REPO="${GIT_REPO:-https://github.com/you/your-gitops-repo}"
GIT_TOKEN="${GIT_TOKEN:-ghp_your_token_with_repo_read}"
ARGOCD_VERSION="${ARGOCD_VERSION:-v3.2.12}"
GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"   # where the template is cloned

# 1. Clone the template (skip if you already have it) and point it at YOUR repo.
if [ ! -d "$GITOPS_DIR" ]; then
  git clone https://github.com/activatedio/argocd-bootstrap "$GITOPS_DIR"
fi
cd "$GITOPS_DIR"
git remote set-url origin "$GIT_REPO"
git push -u origin main

# 2. Install ArgoCD (one target runs all phases above).
make install \
  GIT_REPO="$GIT_REPO" \
  GIT_TOKEN="$GIT_TOKEN" \
  ARGOCD_VERSION="$ARGOCD_VERSION"

# 3. Publish the rendered manifests so ArgoCD reads the same values back.
git commit -am "bootstrap argo-cd" && git push

echo
echo "✓ ArgoCD is installed and self-managing. Next: ./02-access-ui.sh"
