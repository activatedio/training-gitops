#!/usr/bin/env bash
# Module 4 — Flux Step 1: Install the CLI and check the cluster
# Installs the flux CLI, then verifies the cluster can run Flux.
set -euo pipefail

# Install the flux CLI.
curl -s https://fluxcd.io/install.sh | sudo bash

# Verify the cluster is compatible with Flux before installing.
flux check --pre
