#!/usr/bin/env bash
# Module 3 — ArgoCD Step 1: Install ArgoCD
# Creates the argocd namespace and applies the upstream install manifest,
# bringing up all of ArgoCD's components (API server, repo server,
# application-controller, etc.) in the argocd namespace.
set -euo pipefail

kubectl create namespace argocd

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait until every pod is Running (Ctrl+C to stop watching).
kubectl get pods -n argocd -w
