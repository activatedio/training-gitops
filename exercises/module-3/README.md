# GitOps for Kubernetes — Module 3 Scripts (ArgoCD)

Hands-on command scripts for **Module 3: ArgoCD**. They deploy
[**podinfo**](https://github.com/stefanprodan/podinfo), pulled from its **Helm
repository** (`https://stefanprodan.github.io/podinfo`) — nothing vendored;
ArgoCD references the chart from a child Application.

The ArgoCD path is **GitOps-first**: instead of piping the install manifest and
driving the `argocd` CLI, you bootstrap a *self-managing* ArgoCD from the
[`activatedio/argocd-bootstrap`](https://github.com/activatedio/argocd-bootstrap)
template (an [argocd-autopilot](https://github.com/argoproj-labs/argocd-autopilot)-style
layout with `default` / `roots` / `cluster-addons` projects), then build an `example`
**app-of-apps root** that deploys podinfo — all through Git commits and the UI.

> Flux deploys the same app in **Module 4** ([exercises/module-4](../module-4)).

## Prerequisites

- A running Kubernetes cluster (local `kind` is used throughout the course)
- `kubectl` pointed at that cluster
- `git`, `make`, and `perl` (preinstalled on macOS/Linux)
- A **Git repo you control** to hold the manifests, and a token with read access
  (a GitHub PAT is fine).

## Layout

```
module-3/
├── README.md
├── argocd/
│   ├── 01-bootstrap-install.sh  # clone template, `make init` + push, then `make install`
│   ├── 02-access-ui.sh          # make password + port-forward the UI
│   ├── 03-install-ingress.sh   # ingress-nginx add-on (in-cluster) + expose the ArgoCD UI
│   ├── 04-add-example-root.sh  # build the example root: add roots/example/podinfo.yaml + example-root
│   └── 05-change-and-sync.sh   # change a chart value, commit, watch it sync
└── manifests/                                          # demo content to copy into your gitops repo
    ├── roots/example/podinfo.yaml                       # podinfo child App, ingress enabled (copied in by 04)
    ├── roots/cluster-addons/sealed-secrets.yaml         # sealed-secrets add-on (see the material)
    ├── roots/cluster-addons/ingress-nginx.yaml          # ingress-nginx add-on, git generator (copied in by 03)
    ├── roots/cluster-addons/cluster-configs/in-cluster/ingress-nginx.yaml  # per-cluster opt-in (copied in by 03)
    └── cluster-resources/in-cluster/argocd-server-ingress.yaml  # ArgoCD UI Ingress (copied in by 03)
```

> The bootstrap template ships **no** add-ons — `roots/cluster-addons/` is empty.
> These demo add-ons live here in the course repo; you add them to your gitops
> clone (the material walks through sealed-secrets; `03` does ingress-nginx).

## How to run

Each script is standalone and commented. Make them executable first:

```bash
chmod +x argocd/*.sh
```

Edit the placeholder variables at the top of `argocd/01-bootstrap-install.sh`
(`GIT_REPO`, `GIT_TOKEN`, `ARGOCD_VERSION`) first. The scripts operate on the
cloned template repo (default `./argocd-bootstrap`, override with `GITOPS_DIR`).

```bash
./argocd/01-bootstrap-install.sh   # clone template, make init + push, then make install
./argocd/02-access-ui.sh           # leave the port-forward running; log in at https://localhost:8080
./argocd/03-install-ingress.sh     # ingress-nginx (in-cluster) + ArgoCD at https://argocd.localtest.me
./argocd/04-add-example-root.sh    # example root + podinfo, exposed at http://podinfo.localtest.me
./argocd/05-change-and-sync.sh     # change a value; watch podinfo sync (or review the App Diff first)
```

> `03-install-ingress.sh` needs the kind cluster to map host 80/443 and label a
> node `ingress-ready` — the Module 1 config does this. If your cluster predates
> it, recreate it (`kind create cluster --config exercises/module-1/kind-config.yaml`)
> and re-run `01-bootstrap-install.sh` before installing ingress.

## Notes

- The bootstrap installs a *self-managing* ArgoCD (autopilot-style layout): the
  `argo-cd` Application syncs ArgoCD's own install, `root` manages the
  `default` / `roots` / `cluster-addons` projects, the `cluster-resources`
  ApplicationSet (default project) handles cluster-scoped resources, and the
  `cluster-addons-root` applies whatever add-ons you put under
  `roots/cluster-addons/`. See the template's own README.
- `03-install-ingress.sh` installs ingress-nginx via a **per-cluster git
  generator**: the ApplicationSet only creates an Application for clusters with a
  `cluster-configs/<cluster>/ingress-nginx.yaml` opt-in (we provide one for
  `in-cluster`), so it does *not* fan out to every connected cluster. It also
  exposes the ArgoCD UI via an SSL-passthrough Ingress (no `server.insecure` —
  port-forward over HTTPS still works). Hosts use `*.localtest.me` (→ 127.0.0.1).
- Workloads arrive via the **app-of-apps roots** pattern, not a directory
  ApplicationSet. `04-add-example-root.sh` builds an `example` root: it commits
  `roots/example/podinfo.yaml` (a child Application, ingress enabled) and an
  `example-root` Application in `projects/roots.yaml`. `root` → `example-root` →
  `podinfo`, reachable at `http://podinfo.localtest.me`.
- podinfo is deployed from its Helm repository, nothing vendored: the child
  Application sources the chart directly.
- To move podinfo to a new chart release, bump `targetRevision:` in
  `roots/example/podinfo.yaml`.
- Port-forwarding the ArgoCD UI is for local/demo use, not production.

## Sources

- argocd-bootstrap template — https://github.com/activatedio/argocd-bootstrap
- ArgoCD Declarative Setup, ApplicationSet & app-of-apps — https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/, https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/, and https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/
- podinfo sample app & Helm chart — https://github.com/stefanprodan/podinfo (Helm repo: https://stefanprodan.github.io/podinfo)
