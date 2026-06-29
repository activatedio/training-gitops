#!/usr/bin/env bash
# Module 3 — ArgoCD Step 5: Add podinfo under apps/
# Deploy podinfo the GitOps way — drop the tiny umbrella chart into apps/podinfo/
# and let the `default` ApplicationSet discover it. The chart isn't vendored: it
# only declares a dependency on podinfo's Helm repository, and ArgoCD pulls it at
# render time using Chart.lock.
#
# After the push, open the UI: the podinfo Application appears OutOfSync.
# Open it, watch the resource tree, and press Sync to converge it to Healthy.
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
# The umbrella chart (Chart.yaml, Chart.lock, values.yaml) in this exercises checkout.
SRC="$(cd "$(dirname "$0")/../manifests/apps/podinfo" && pwd)"

cd "$GITOPS_DIR"
mkdir -p apps
rm -rf apps/podinfo
cp -r "$SRC" apps/podinfo

git add apps/podinfo
git commit -m "add podinfo (helm repo chart)" && git push

echo
echo "✓ podinfo chart committed. In the UI: open the podinfo app (OutOfSync) and press Sync."
