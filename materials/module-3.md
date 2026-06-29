# Module 3 – Hands-On: ArgoCD and Flux

## Introduction

Let's use GitOps to deploy the same sample application — [podinfo](https://github.com/stefanprodan/podinfo),
a small web app published as a Helm chart — to a Kubernetes cluster using ArgoCD
and Flux. To follow along, you will need:

* Docker
* `kind` and `kubectl`
* A GitHub account
* And Make

### The cluster

We'll reuse the same local `kind` cluster from Module 1. If it's still running you're set — `kubectl get nodes` should list the `gitops-demo` control-plane and two workers. If you tore it down (or skipped Module 1), recreate it from the config in the exercises:

```bash
kind create cluster --config exercises/module-1/kind-config.yaml
kubectl get nodes      # the gitops-demo control-plane + 2 workers
```

`kind delete cluster --name gitops-demo` removes it again when you're done.

## Walkthrough 1 — ArgoCD: bootstrap once, then drive everything from Git

Let's start by installing ArgoCD using a GitOps approach similar to the popular argocd-autopilot project. In fact, feel free to use that project as a starting point for your own ArgoCD install.

We start from a small **bootstrap template** `github.com/activatedio/argocd-bootstrap` that installs an ArgoCD instance which
*manages itself from Git*. After that you can push changes to the Git repoisitory to manage the ArgoCD installation.

The bootstrap will wire up three things:

1. An `argo-cd` Application that syncs ArgoCD's own install.
2. A `root` Application that manages your `projects/`
3. A `default`ApplicationSet that turns every directory under `apps` into an
Application automatically.

We will deploy the podinfo application using a subdirectory under `apps`

### Clone the template into a repo you control

First, clone the template and push into a repo you control.

```bash
git clone https://github.com/activatedio/argocd-bootstrap
cd argocd-bootstrap
git remote set-url origin https://github.com/you/your-gitops-repo
git push -u origin main
```

### Render the templates, push, then install

While we will use a Git repository to manage the ArgoCD installation, we need to boostrap it with local manifests that contain correct values for our installation and are in sync with the referenced repository on GitHub. 

These steps use of Make, which you can install with any package manager, including Homebew on a Mac. If you really don't want to use make you can just run the commands directly.

First, create a GitHub Personal Access Token (PAT) with the `repo` scope. Then export it along with the repo URL and version of ArgoCD you want to install.

```bash
export GIT_REPO=https://github.com/you/your-gitops-repo
export GIT_TOKEN=ghp_your_token
export ARGOCD_VERSION=v3.2.12
```

Render the templates and publish them. This only edits files in your repo nothing will be applied yet to the cluster.

```bash
make init      # bakes GIT_REPO + ARGOCD_VERSION into the manifests
git commit -am "init gitops repo" && git push
```

Now install. This creates the repo-access secret and applies the main ArgoCD manifest.

```bash
make install   # repo secret + ArgoCD install + self-management
```

When it returns, check that the control plane came up and is already managing itself.

```bash
make status                  # lists the argo-cd, root, and default objects
kubectl get pods -n argocd   # every component should be Running
```

You want the `argo-cd`, `root`, and `default` objects reporting `Synced` / `Healthy`. If `argo-cd` shows `OutOfSync`, the rendered manifests probably weren't pushed before `make install` ran; push them and it converges.

### Open the UI

```bash
make password        # prints the initial admin password (user: admin)
make port-forward    # forwards the console to https://localhost:8080
```

Log in and see the installed applications.

### Install podinfo from a Helm repository

Deploy podinfo the GitOps way: drop a directory into `apps/podinfo/` and let the
ApplicationSet discover it. Since Module 2 made the case for Helm, we'll pull
podinfo straight from its **Helm repository** — nothing about the chart is copied
into your repo. All `apps/podinfo/` holds is a tiny *umbrella* chart that
references the upstream chart as a dependency:

`apps/podinfo/Chart.yaml`

```yaml
apiVersion: v2
name: podinfo
version: 0.1.0
dependencies:
  - name: podinfo
    version: 6.14.0
    repository: https://stefanprodan.github.io/podinfo
```

`apps/podinfo/values.yaml` (override the chart's values — keyed by the dependency name)

```yaml
podinfo:
  replicaCount: 1
  ui:
    message: "Deployed by GitOps"
```

Run `helm dependency update apps/podinfo` once to generate `Chart.lock` (which
pins the resolved version), commit the three small files, and push:

```bash
git add apps/podinfo
git commit -m "add podinfo (helm repo chart)" && git push
```

On its next git poll the ApplicationSet creates a `podinfo` Application. ArgoCD
reads the `Chart.lock`, pulls podinfo from the Helm repository, renders it, and
syncs — the chart is fetched on demand, never vendored. To move to a new chart
release later, bump the dependency `version`, refresh `Chart.lock`, commit, and
ArgoCD shows the diff before it syncs.

## Walkthrough 2 — Flux: the GitOps Toolkit

Let's install the same podinfo application using the Flux toolkit.
Flux's reconciliation philosophy is identical to ArgoCD's — pull from Git converge continuously.
moving parts are exposed.

Before we start, let's reset the kind cluster so we can start fresh.

```bash
kind delete cluster --name gitops-demo
kind create cluster --config exercises/module-1/kind-config.yaml
kubectl get nodes
```
### Install the CLI and check the cluster

```bash
curl -s https://fluxcd.io/install.sh | sudo bash
flux check --pre
```

### Step 2: Bootstrap Flux into a Git repo

Flux *bootstraps* itself by
committing its own controllers into a Git repository, then configuring
the cluster to sync from that repo. We can us the same GitHub PAT you created previously. We will re-export it here just to be sure.

``` bash
export GITHUB_USER=you
export GITHUB_REPO=your-repo
export GIT_TOKEN=ghp_your_token
```

Now the install

```
flux bootstrap github  --owner=$GITHUB_USER --repository=$GITHUB_REPO --branch=main --path=clusters/my-cluster --personal
```

This brings up the main controllers in the flux-system namespace, including
source-controller, kustomize-controller, helm-controller, and
notification-controller.

### Step 3: Declare the source

First tell Flux where the chart lives. A `HelmRepository` source points the
source-controller at podinfo's Helm repository — the same one ArgoCD pulled
from — and it polls the repo index on an interval.

```bash
flux create source helm podinfo \
--url=https://stefanprodan.github.io/podinfo \
--interval=1m \
--export > ./clusters/my-cluster/podinfo-source.yaml
```

### Step 4: Declare the HelmRelease

Now hand the chart to the helm-controller. A `HelmRelease` names the chart in
that repository (`podinfo`, pinned to a version) and the helm-controller installs
and upgrades the actual Helm release to match — the same controller Module 2
introduced.

```bash
flux create helmrelease podinfo \
  --source=HelmRepository/podinfo \
  --chart=podinfo \
  --chart-version=6.14.0 \
  --target-namespace=podinfo \
  --create-target-namespace=true \
  --interval=5m \
  --export > ./clusters/my-cluster/podinfo-helmrelease.yaml
```

Commit both files. Because Flux is already syncing this repo, the moment
your commit lands the controllers pick it up and deploy podinfo —
no extra apply needed.

```bash
git add -A && git commit -m "deploy podinfo (helm)" && git push
```

### Step 5: Observe — from the command line

Flux has no Sync button, so you watch with the CLI. You can also force
an immediate reconcile instead of waiting for the interval.

```bash

flux get helmreleases
flux get sources git
# force an immediate reconcile
flux reconcile helmrelease podinfo --with-source
# tail controller logs when something looks off
flux logs --follow
```

That's the Flux story: a source plus a HelmRelease, committed to Git and
reconciled by a chain of single-purpose controllers. The pipeline is code, not
clicks — which is exactly why Git-native teams like it.

## Side by Side: Choosing for Your Stack

Both tools just deployed the identical podinfo app and will both keep it
matching Git. The difference is shape and ergonomics, not capability.
Use this table to map each tool to how your team actually works.

| **Dimension** | **ArgoCD** | **Flux** |
|----|----|----|
| Deployment model | Application-centric: one Application CRD per app, reconciled by the application-controller | Toolkit-centric: a chain of source-controller, kustomize-controller, and helm-controller |
| Time to first deploy | Fast once bootstrapped: a template installs a self-managing ArgoCD, then drop apps under `apps/*` and Sync (or auto-sync) | Moderate: bootstrap writes Flux into a Git repo first, then add a source plus a Kustomization or HelmRelease |
| Developer friction | Low for newcomers: GUI guides you; CLI optional | Low for Git-native teams: everything is a committed CR; no GUI to learn |
| Observability | Rich built-in web UI: live resource tree, diffs, sync history, rollback | CLI-first: flux get / flux logs / events; UI via optional add-ons (Weave GitOps, Capacitor) |
| Drift handling | Detects drift; self-heal and prune are opt-in toggles | Continuous reconcile; prune and health checks set per Kustomization / HelmRelease |
| Multi-tenancy | AppProjects scope repos, clusters, and namespaces | Per-namespace controllers plus RBAC; tenants own their CRs |
| Best fit | Teams that want a console and visual sync/rollback out of the box | Teams that live in Git and want composable, code-only pipelines |

### The one-line rule of thumb

Reach for **ArgoCD** when you want a console out of the box — visual
sync, diffs, and rollback that an on-call engineer can drive at 2 a.m.
Reach for **Flux** when your team lives in Git and prefers composable,
code-only pipelines with no extra UI to operate. The GitOps pattern
underneath — declare in Git, pull, reconcile, correct drift — is
identical either way, so you are choosing a workflow, not a philosophy.

### Wrap-up

You've now deployed the same app with both tools and seen exactly where
they ask for your attention: ArgoCD at the Sync button, Flux at the Git
commit. Spin up a throwaway cluster, run both walkthroughs back to back,
and notice which one feels like home. That instinct — plus the table
above — is how you'll choose the right GitOps engine for your
infrastructure.

**Sources**

* argocd-bootstrap template — github.com/activatedio/argocd-bootstrap
* ArgoCD Declarative Setup, ApplicationSet & app-of-apps — argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/, /operator-manual/applicationset/, and /operator-manual/cluster-bootstrapping/
* Flux Getting Started & CLI — fluxcd.io/flux/get-started/ and fluxcd.io/flux/cmd/
* podinfo sample app & Helm chart — github.com/stefanprodan/podinfo · Helm repo: stefanprodan.github.io/podinfo
