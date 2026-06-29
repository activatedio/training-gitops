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
│   ├── 03-add-example-root.sh   # build the example root: add roots/example/podinfo.yaml + example-root, commit
│   ├── 04-change-and-sync.sh    # change a chart value, commit, watch it sync
│   └── 05-enable-ingress.sh     # ingress-nginx add-on + expose ArgoCD & podinfo at *.localtest.me
└── manifests/                                          # demo content to copy into your gitops repo
    ├── roots/example/podinfo.yaml                       # podinfo child Application (copied in by 03)
    ├── roots/cluster-addons/sealed-secrets.yaml         # sealed-secrets add-on (see the material)
    ├── roots/cluster-addons/ingress-nginx.yaml          # ingress-nginx add-on (copied in by 05)
    └── cluster-resources/in-cluster/argocd-server-ingress.yaml  # ArgoCD UI Ingress (copied in by 05)
```

> The bootstrap template ships **no** add-ons — `roots/cluster-addons/` is empty.
> These demo add-ons live here in the course repo; you add them to your gitops
> clone (the material walks through sealed-secrets, and `05` does ingress-nginx).

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
./argocd/03-add-example-root.sh    # build the example root + podinfo; watch root -> example-root -> podinfo
./argocd/04-change-and-sync.sh     # change a value; watch podinfo sync (or review the App Diff first)
./argocd/05-enable-ingress.sh      # then open https://argocd.localtest.me and http://podinfo.localtest.me
```

> `05-enable-ingress.sh` needs the kind cluster to map host 80/443 and label a
> node `ingress-ready` — the Module 1 config does this. If your cluster predates
> it, recreate it (`kind create cluster --config exercises/module-1/kind-config.yaml`)
> and re-run `01-bootstrap-install.sh` before enabling ingress.

## Notes

- The bootstrap installs a *self-managing* ArgoCD (autopilot-style layout): the
  `argo-cd` Application syncs ArgoCD's own install, `root` manages the
  `default` / `roots` / `cluster-addons` projects, the `cluster-resources`
  ApplicationSet (default project) handles cluster-scoped resources, and the
  `cluster-addons-root` carries add-ons (a commented `sealed-secrets` example).
  See the template's own README.
- Workloads arrive via the **app-of-apps roots** pattern, not a directory
  ApplicationSet. `03-add-example-root.sh` builds an `example` root: it commits
  `roots/example/podinfo.yaml` (a child Application) and an `example-root`
  Application in `projects/roots.yaml`. `root` → `example-root` → `podinfo`.
- podinfo is deployed from its Helm repository, nothing vendored: the child
  Application sources the chart directly.
- To move podinfo to a new chart release, bump `targetRevision:` in
  `roots/example/podinfo.yaml`.
- `05-enable-ingress.sh` installs the ingress-nginx add-on (Helm, kind-tuned
  values), exposes the ArgoCD UI via an SSL-passthrough Ingress (no
  `server.insecure` — port-forward over HTTPS still works), and turns on
  podinfo's chart ingress. Hosts use `*.localtest.me` (resolves to 127.0.0.1).
- Port-forwarding the ArgoCD UI is for local/demo use, not production.

## Sources

- argocd-bootstrap template — https://github.com/activatedio/argocd-bootstrap
- ArgoCD Declarative Setup, ApplicationSet & app-of-apps — https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/, https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/, and https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/
- podinfo sample app & Helm chart — https://github.com/stefanprodan/podinfo (Helm repo: https://stefanprodan.github.io/podinfo)
