#!/usr/bin/env bash
# Module 3 — ArgoCD Step 7: Turn on auto-sync
# Once you trust the loop, hand it the keys. Put the `automated` block back on
# the `default` ApplicationSet: every app under apps/* now syncs itself,
# self-heals manual drift, and prunes what you delete from Git. The diff-then-
# click step disappears — commit a change and ArgoCD applies it on its own.
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
cd "$GITOPS_DIR"

# Re-insert the `automated:` block right under the template's syncPolicy.
if grep -q '^        automated:' projects/default.yaml; then
  echo "Automated sync already enabled — nothing to do."
else
  perl -0777 -pi -e \
    's/(      syncPolicy:\n)(        syncOptions:)/${1}        automated:\n          prune: true\n          selfHeal: true\n${2}/' \
    projects/default.yaml
  git commit -am "apps: enable automated sync" && git push
  echo "✓ Automated sync enabled for everything under apps/*."
fi
