#!/usr/bin/env bash
# Module 3 — ArgoCD Step 3: Open the UI
# The bootstrap template's Makefile wraps the two things you need: the initial
# admin password and a port-forward to the console. Username is "admin".
#
# Tip: `make port-forward` blocks — leave it running in its own terminal and
# open https://localhost:8080. You'll see the argo-cd, root, and default
# objects already Synced and Healthy: the control plane managing itself.
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
cd "$GITOPS_DIR"

echo "Initial admin password (username: admin):"
make password

# Forward the console to https://localhost:8080 (blocks).
make port-forward
