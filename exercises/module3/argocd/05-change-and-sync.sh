#!/usr/bin/env bash
# Module 3 — ArgoCD Step 6: Change the guestbook and apply it from the diff
# The everyday GitOps loop. We bump the container image tag, commit, and push.
# ArgoCD marks guestbook OutOfSync on its next poll.
#
# Then — BEFORE syncing — open the App Diff panel in the UI. You'll see exactly
# this one-line image change: desired (Git) beside live (cluster). Reviewing the
# diff before it lands is the whole point of manual sync. Press Sync to roll the
# Deployment to the new image.
set -euo pipefail

GITOPS_DIR="${GITOPS_DIR:-argocd-bootstrap}"
cd "$GITOPS_DIR"

DEPLOY=apps/guestbook/guestbook-ui-deployment.yaml

# Bump gb-frontend v5 -> v4 (idempotent).
if grep -q 'gb-frontend:v5' "$DEPLOY"; then
  perl -pi -e 's{gb-frontend:v5}{gb-frontend:v4}' "$DEPLOY"
  git commit -am "guestbook: pin gb-frontend v4" && git push
  echo "✓ Image bumped to v4 and pushed."
  echo "  In the UI: guestbook -> App Diff (review), then Sync."
else
  echo "Image is not at v5 (already changed?) — edit $DEPLOY by hand to try another tag."
fi
