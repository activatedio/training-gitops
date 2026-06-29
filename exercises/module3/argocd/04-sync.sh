#!/usr/bin/env bash
# Module 3 — ArgoCD Step 4: Sync — the click that closes the loop
# A new app is OutOfSync until you sync it. In the UI this is the Sync button;
# from the CLI it's the command below. Then optionally enable automated sync so
# future Git commits apply themselves, with self-heal and prune.
set -euo pipefail

# Converge the cluster to the desired state in Git.
argocd app sync guestbook

# Watch it reach Synced / Healthy.
argocd app get guestbook

# Optional: hands-off mode — auto-apply future commits, self-heal drift,
# and prune resources deleted from Git.
argocd app set guestbook --sync-policy automated --self-heal --auto-prune
