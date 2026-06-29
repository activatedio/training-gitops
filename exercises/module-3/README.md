# GitOps for Kubernetes — Module 3 Scripts

Hands-on command scripts extracted from **Module 3: ArgoCD and Flux**.
Both walkthroughs deploy the same canonical **guestbook** app
(`github.com/argoproj/argocd-example-apps`, path `guestbook`) two different
ways so you can compare the tools on an identical workload.

The ArgoCD path is **GitOps-first**: instead of piping the install manifest and
driving the `argocd` CLI, you bootstrap a *self-managing* ArgoCD from the
[`activatedio/argocd-bootstrap`](https://github.com/activatedio/argocd-bootstrap)
template, ship the guestbook by dropping files under `apps/*`, and then do
everything else through Git commits and the web UI.

## Prerequisites

- A running Kubernetes cluster (local `k3d`, `kind`, or Docker Desktop is fine)
- `kubectl` pointed at that cluster
- `git`, `make`, and `perl` (preinstalled on macOS/Linux)
- A **Git repo you control** to hold the manifests, and a token with read access
  (a GitHub PAT is fine). Both walkthroughs need this.

## Layout

```
module-3/
├── README.md
├── argocd/
│   ├── 01-bootstrap-install.sh  # clone template + `make install` a self-managing ArgoCD
│   ├── 02-access-ui.sh          # make password + port-forward the UI
│   ├── 03-manual-first.sh       # turn the ApplicationSet's auto-sync OFF (sync by hand)
│   ├── 04-add-guestbook.sh      # drop the guestbook under apps/ + commit
│   ├── 05-change-and-sync.sh    # bump the image, review the diff in the UI, Sync
│   └── 06-enable-autosync.sh    # turn auto-sync back ON for apps/*
├── flux/
│   ├── 01-install-cli.sh        # install flux CLI + pre-flight check
│   ├── 02-bootstrap.sh          # bootstrap Flux into a Git repo
│   ├── 03-create-source.sh      # declare the GitRepository source
│   ├── 04-create-kustomization.sh  # declare the Kustomization + commit
│   └── 05-observe.sh            # CLI observability (get / reconcile / logs)
└── manifests/
    ├── applicationset-syncpolicy.md       # the manual/auto sync-policy edits, explained
    └── apps/guestbook/                    # guestbook manifests to copy into your repo
        ├── guestbook-ui-deployment.yaml
        └── guestbook-ui-svc.yaml
```

## How to run

Each script is standalone and commented. Make them executable first:

```bash
chmod +x argocd/*.sh flux/*.sh
```

### ArgoCD path

Edit the placeholder variables at the top of `argocd/01-bootstrap-install.sh`
(`GIT_REPO`, `GIT_TOKEN`, `ARGOCD_VERSION`) first. The scripts operate on the
cloned template repo (default `./argocd-bootstrap`, override with `GITOPS_DIR`).

```bash
./argocd/01-bootstrap-install.sh   # clone template, make install, commit + push
./argocd/02-access-ui.sh           # leave the port-forward running; log in at https://localhost:8080
./argocd/03-manual-first.sh        # sync by hand to start (auto-sync OFF)
./argocd/04-add-guestbook.sh       # then in the UI: open guestbook (OutOfSync) and press Sync
./argocd/05-change-and-sync.sh     # then in the UI: review App Diff, then Sync
./argocd/06-enable-autosync.sh     # hand the loop the keys
```

### Flux path

Edit the placeholder variables at the top of `flux/02-bootstrap.sh`
(`GITHUB_USER`, `GITHUB_TOKEN`, repo name, path) before running.

```bash
./flux/01-install-cli.sh
./flux/02-bootstrap.sh
./flux/03-create-source.sh
./flux/04-create-kustomization.sh
./flux/05-observe.sh
```

## Notes

- The ArgoCD path installs a *self-managing* ArgoCD: the `argo-cd` Application
  syncs ArgoCD's own install, `root` manages `projects/`, and the `default`
  ApplicationSet turns every `apps/*` directory into an Application. See the
  template's own README for the full picture.
- `03-manual-first.sh` / `06-enable-autosync.sh` toggle one block in
  `projects/default.yaml`; the before/after YAML is in
  [`manifests/applicationset-syncpolicy.md`](manifests/applicationset-syncpolicy.md).
- The guestbook repo's default branch is `master`; the Flux source uses
  `--branch=master` to match. Adjust if upstream changes.
- Port-forwarding the ArgoCD UI is for local/demo use, not production.
- `flux bootstrap` commits Flux's own controllers into your Git repo — this is
  intentional ("Flux manages Flux the GitOps way").

## Sources

- argocd-bootstrap template — https://github.com/activatedio/argocd-bootstrap
- ArgoCD Declarative Setup, ApplicationSet & app-of-apps — https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/, https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/, and https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/
- Flux Getting Started & CLI — https://fluxcd.io/flux/get-started/ and https://fluxcd.io/flux/cmd/
- Guestbook example app — https://github.com/argoproj/argocd-example-apps (path: guestbook)
