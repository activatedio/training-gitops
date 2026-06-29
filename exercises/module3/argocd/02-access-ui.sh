#!/usr/bin/env bash
# Module 3 — ArgoCD Step 2: Reach the UI and log in
# The API server isn't exposed by default. Port-forward it, then grab the
# auto-generated admin password. Username is "admin".
#
# Tip: run the port-forward in its own terminal and leave it running, then
# open https://localhost:8080 in a browser.
set -euo pipefail

# Print the initial admin password first (handy to copy before forwarding).
echo "Initial admin password (username: admin):"
argocd admin initial-password -n argocd

# Forward local port 8080 to the argocd-server service.
# This blocks; visit https://localhost:8080 while it runs.
kubectl port-forward svc/argocd-server -n argocd 8080:443
