#!/usr/bin/env bash
# Module 3 — ArgoCD: Change podinfo and watch GitOps apply it
# The everyday GitOps loop. We change a Helm value (the UI banner) on the podinfo
# child Application, commit, and push. The dev-root is auto-synced, so ArgoCD
# re-renders and rolls podinfo to the new value on its own — open the podinfo app
# in the UI to watch it converge (or use the App Diff panel to see the change
# before it lands).
#
# (To move to a new chart release instead, bump `targetRevision:` in podinfo.yaml.)
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
cd "$GITOPS_DIR"

APP=roots/dev/podinfo.yaml

# Change the UI banner message (idempotent-ish: only flips the default).
if grep -q 'Deployed by GitOps' "$APP"; then
  perl -pi -e 's{Deployed by GitOps}{Updated via GitOps}' "$APP"
  git commit -am "podinfo: change ui.message" && git push
  echo "✓ ui.message changed and pushed."
  echo "  In the UI: open podinfo and watch it sync (or review the App Diff first)."
else
  echo "ui.message already changed — edit $APP by hand to try another value."
fi
