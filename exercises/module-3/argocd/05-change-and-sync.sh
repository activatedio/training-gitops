#!/usr/bin/env bash
# Module 3 — ArgoCD Step 6: Change podinfo and apply it from the diff
# The everyday GitOps loop, Helm-style. We change a chart value (the UI banner),
# commit, and push. ArgoCD re-renders the chart and marks podinfo OutOfSync.
#
# Then — BEFORE syncing — open the App Diff panel in the UI. You'll see exactly
# the value change reflected in the rendered Deployment: desired (Git) beside
# live (cluster). Reviewing the diff before it lands is the whole point of manual
# sync. Press Sync to roll it out.
#
# (To move to a new chart release instead, bump the dependency version in
#  apps/podinfo/Chart.yaml and refresh Chart.lock with `helm dependency update`.)
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
cd "$GITOPS_DIR"

VALUES=apps/podinfo/values.yaml

# Change the UI banner message (idempotent-ish: only flips the default).
if grep -q 'Deployed by GitOps' "$VALUES"; then
  perl -pi -e 's{Deployed by GitOps}{Updated via a reviewed diff}' "$VALUES"
  git commit -am "podinfo: change ui.message" && git push
  echo "✓ ui.message changed and pushed."
  echo "  In the UI: podinfo -> App Diff (review), then Sync."
else
  echo "ui.message already changed — edit $VALUES by hand to try another value."
fi
