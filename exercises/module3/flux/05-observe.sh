#!/usr/bin/env bash
# Module 3 — Flux Step 5: Observe — from the command line
# Flux has no Sync button, so you watch with the CLI. You can also force an
# immediate reconcile instead of waiting for the interval, and tail the
# controller logs when something looks off.
set -euo pipefail

# Current state of your Kustomizations and Git sources.
flux get kustomizations
flux get sources git

# Force an immediate reconcile (pull the source too).
flux reconcile kustomization guestbook --with-source

# Tail controller logs to debug.
flux logs --follow
