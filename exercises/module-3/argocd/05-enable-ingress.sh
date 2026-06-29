#!/usr/bin/env bash
# Module 3 — ArgoCD: Expose ArgoCD + podinfo through an ingress controller
# Moves beyond `kubectl port-forward`. This:
#   1. enables the ingress-nginx cluster-addon (Helm, kind-tuned values)
#   2. adds an Ingress for the ArgoCD UI (nginx SSL passthrough)
#   3. turns on podinfo's chart ingress
# After it syncs: https://argocd.localtest.me and http://podinfo.localtest.me.
#
# PREREQUISITE: your kind cluster must map host 80/443 + label a node
# ingress-ready. The Module 1 config does this; if your cluster predates it:
#   kind delete cluster --name gitops-demo
#   kind create cluster --config exercises/module-1/kind-config.yaml
#   make install        # from the gitops clone, to reinstall ArgoCD
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
SRC="$(cd "$(dirname "$0")/../manifests" && pwd)"

cd "$GITOPS_DIR"

# 1. Enable the ingress-nginx add-on (overwrite the commented template file).
cp "$SRC/roots/cluster-addons/ingress-nginx.yaml" roots/cluster-addons/ingress-nginx.yaml

# 2. ArgoCD UI Ingress, applied via the cluster-resources ApplicationSet.
mkdir -p cluster-resources/in-cluster
cp "$SRC/cluster-resources/in-cluster/argocd-server-ingress.yaml" cluster-resources/in-cluster/

# 3. Turn on podinfo's ingress (append to its Helm values, idempotent).
APP=roots/example/podinfo.yaml
if ! grep -q 'podinfo.localtest.me' "$APP"; then
  perl -0777 -pi -e 's{(^          message:.*\n)}{$1        ingress:\n          enabled: true\n          className: nginx\n          hosts:\n            - host: podinfo.localtest.me\n              paths:\n                - path: /\n                  pathType: ImplementationSpecific\n}m' "$APP"
fi

git add roots/cluster-addons/ingress-nginx.yaml cluster-resources/in-cluster/argocd-server-ingress.yaml "$APP"
git commit -m "expose argocd + podinfo via ingress-nginx" && git push

echo
echo "✓ Ingress enabled. Once synced:"
echo "    ArgoCD UI : https://argocd.localtest.me   (accept the self-signed cert)"
echo "    podinfo   : http://podinfo.localtest.me"
