#!/usr/bin/env bash
# Module 3 — ArgoCD Step 5: Add the guestbook under apps/
# Deploy the guestbook the GitOps way — drop its manifests into apps/guestbook/
# and let the `default` ApplicationSet discover them. No app to register by hand.
#
# After the push, open the UI: the guestbook Application appears OutOfSync.
# Open it, watch the resource tree, and press Sync to converge it to Healthy.
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
# Where the vendored guestbook manifests live in this exercises checkout.
SRC="$(cd "$(dirname "$0")/../manifests/apps/guestbook" && pwd)"

cd "$GITOPS_DIR"
mkdir -p apps/guestbook
cp "$SRC/guestbook-ui-deployment.yaml" "$SRC/guestbook-ui-svc.yaml" apps/guestbook/

git add apps/guestbook
git commit -m "add guestbook" && git push

echo
echo "✓ guestbook committed. In the UI: open the guestbook app (OutOfSync) and press Sync."
