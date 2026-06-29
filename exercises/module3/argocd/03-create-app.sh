#!/usr/bin/env bash
# Module 3 — ArgoCD Step 3 (CLI form): Create the guestbook Application
# The imperative one-liner equivalent of manifests/guestbook-application.yaml.
# It names the source (repo, path, revision) and the destination
# (cluster, namespace).
#
# Declarative alternative:
#   kubectl apply -n argocd -f manifests/guestbook-application.yaml
set -euo pipefail

argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace guestbook
