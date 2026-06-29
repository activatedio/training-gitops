#!/usr/bin/env bash
# Module 3 — ArgoCD Step 4: Start with sync by hand
# The template's `default` ApplicationSet (projects/default.yaml) ships with
# automated sync ON. We turn it OFF first so every app under apps/* comes up
# OutOfSync and waits for us — letting us review each diff in the UI before it
# lands. This is a single commit; the `root` Application reconciles it.
#
# See ../manifests/applicationset-syncpolicy.md for the before/after YAML.
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
cd "$GITOPS_DIR"

# Remove the `automated:` block from the ApplicationSet template (idempotent).
if grep -q '^        automated:' projects/default.yaml; then
  perl -0777 -pi -e \
    's/\n        automated:\n          prune: true\n          selfHeal: true//' \
    projects/default.yaml
  git commit -am "apps: manual sync to start" && git push
  echo "✓ Automated sync disabled. New apps under apps/* will wait for a manual Sync."
else
  echo "Already in manual mode (no automated block found) — nothing to do."
fi
