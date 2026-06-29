#!/usr/bin/env bash
# Module 3 — ArgoCD Step 1+2: Bootstrap a self-managing ArgoCD from a template
#
# Instead of piping the upstream install manifest and driving ArgoCD with the
# `argocd` CLI, we clone a bootstrap template and let it install an ArgoCD that
# manages ITSELF from Git. After this, every change is a commit you review in
# the UI — not an imperative command.
#
# The flow is render -> push -> install, in that order. Rendering and pushing
# BEFORE installing means ArgoCD reads back exactly what you applied, so its
# first reconcile is already in sync:
#   make init     bakes GIT_REPO + ARGOCD_VERSION into the manifests (files only)
#   git push      publishes the rendered repo
#   make install  creates the repo secret, applies the ArgoCD install, waits,
#                 then applies the self-managing `root` + `argo-cd` Applications
#
# EDIT THESE before running (Make reads them from the environment):
set -euo pipefail

export GIT_REPO="${GIT_REPO:-https://github.com/you/your-gitops-repo}"
export GIT_TOKEN="${GIT_TOKEN:-ghp_your_token_with_repo_read}"
export ARGOCD_VERSION="${ARGOCD_VERSION:-v3.2.12}"
GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"   # where the template is cloned

# 1. Clone the template (skip if you already have it) and point it at YOUR repo.
if [ ! -d "$GITOPS_DIR" ]; then
  git clone https://github.com/activatedio/argocd-bootstrap "$GITOPS_DIR"
fi
cd "$GITOPS_DIR"
git remote set-url origin "$GIT_REPO"
git push -u origin main

# 2. Render the templates with your variables (edits files only, no cluster).
make init

# 3. Publish the rendered manifests so ArgoCD reads the same values back.
git commit -am "init gitops repo" && git push

# 4. Install: repo secret + ArgoCD install + self-management. The working tree
#    is already rendered and pushed, so this only talks to the cluster.
make install

# 5. Check the install: the argo-cd, root, and default objects should report
#    Synced / Healthy, and every pod in the argocd namespace should be Running.
make status
kubectl get pods -n argocd

echo
echo "✓ ArgoCD is installed and self-managing. Next: ./02-access-ui.sh"
