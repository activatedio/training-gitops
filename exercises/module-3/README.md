# GitOps for Kubernetes — Module 3 Scripts

Hands-on command scripts extracted from **Module 3: ArgoCD and Flux**.
Both walkthroughs deploy the same app — [**podinfo**](https://github.com/stefanprodan/podinfo),
pulled from its **Helm repository** (`https://stefanprodan.github.io/podinfo`) —
two different ways so you can compare the tools on an identical workload. The
chart is never vendored: ArgoCD references it from a child Application and Flux
pulls it through a `HelmRepository` source.

The ArgoCD path is **GitOps-first**: instead of piping the install manifest and
driving the `argocd` CLI, you bootstrap a *self-managing* ArgoCD from the
[`activatedio/argocd-bootstrap`](https://github.com/activatedio/argocd-bootstrap)
template (an [argocd-autopilot](https://github.com/argoproj-labs/argocd-autopilot)-style
layout with `default` / `roots` / `cluster-addons` projects), then build an `example`
**app-of-apps root** that deploys podinfo — all through Git commits and the UI.

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
│   ├── 01-bootstrap-install.sh  # clone template, `make init` + push, then `make install`
│   ├── 02-access-ui.sh          # make password + port-forward the UI
│   ├── 03-add-example-root.sh       # build the example root: add roots/example/podinfo.yaml + example-root, commit
│   └── 04-change-and-sync.sh    # change a chart value, commit, watch it sync
├── flux/
│   ├── 01-install-cli.sh        # install flux CLI + pre-flight check
│   ├── 02-bootstrap.sh          # bootstrap Flux into a Git repo
│   ├── 03-create-source.sh      # declare the HelmRepository source (podinfo)
│   ├── 04-create-helmrelease.sh # declare the HelmRelease (helm-controller) + commit
│   └── 05-observe.sh            # CLI observability (get / reconcile / logs)
└── manifests/
    └── roots/example/podinfo.yaml             # podinfo child Application (copied in by 03)
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
./argocd/01-bootstrap-install.sh   # clone template, make init + push, then make install
./argocd/02-access-ui.sh           # leave the port-forward running; log in at https://localhost:8080
./argocd/03-add-example-root.sh        # build the example root + podinfo; watch root -> example-root -> podinfo
./argocd/04-change-and-sync.sh     # change a value; watch podinfo sync (or review the App Diff first)
```

### Flux path

Edit the placeholder variables at the top of `flux/02-bootstrap.sh`
(`GITHUB_USER`, `GITHUB_TOKEN`, repo name, path) before running.

```bash
./flux/01-install-cli.sh
./flux/02-bootstrap.sh
./flux/03-create-source.sh
./flux/04-create-helmrelease.sh
./flux/05-observe.sh
```

## Notes

- The ArgoCD path installs a *self-managing* ArgoCD (autopilot-style layout):
  the `argo-cd` Application syncs ArgoCD's own install, `root` manages the
  `default` / `roots` / `cluster-addons` projects, the `cluster-resources`
  ApplicationSet (default project) handles cluster-scoped resources, and the
  `cluster-addons-root` carries add-ons (a commented `sealed-secrets` example).
  See the template's own README.
- Workloads arrive via the **app-of-apps roots** pattern, not a directory
  ApplicationSet. `03-add-example-root.sh` builds an `example` root: it commits
  `roots/example/podinfo.yaml` (a child Application) and an `example-root` Application in
  `projects/roots.yaml`. `root` → `example-root` → `podinfo`.
- podinfo is deployed from its Helm repository, nothing vendored: under ArgoCD
  the child Application sources the chart directly; under Flux a `HelmRepository`
  source + `HelmRelease` (helm-controller) does the same.
- To move podinfo to a new chart release, bump `targetRevision:` in
  `roots/example/podinfo.yaml`.
- Port-forwarding the ArgoCD UI is for local/demo use, not production.
- `flux bootstrap` commits Flux's own controllers into your Git repo — this is
  intentional ("Flux manages Flux the GitOps way").

## Sources

- argocd-bootstrap template — https://github.com/activatedio/argocd-bootstrap
- ArgoCD Declarative Setup, ApplicationSet & app-of-apps — https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/, https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/, and https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/
- Flux Getting Started & CLI — https://fluxcd.io/flux/get-started/ and https://fluxcd.io/flux/cmd/
- podinfo sample app & Helm chart — https://github.com/stefanprodan/podinfo (Helm repo: https://stefanprodan.github.io/podinfo)
