#!/usr/bin/env bash
# Module 4 — Flux Step 5: Observe — from the command line
# Flux has no Sync button, so you watch with the CLI. You can also force an
# immediate reconcile instead of waiting for the interval, and tail the
# controller logs when something looks off.
set -euo pipefail

# Current state of your HelmReleases and Helm sources.
flux get helmreleases
flux get sources helm

# Force an immediate reconcile (pull the source too).
flux reconcile helmrelease podinfo --with-source

# Tail controller logs to debug.
flux logs --follow
