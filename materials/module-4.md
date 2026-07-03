# Module 4 – Hands-On: Flux

## Introduction

In [Module 3](module-3.md) we deployed [podinfo](https://github.com/stefanprodan/podinfo)
with ArgoCD. Now we'll deploy the **same** app with **Flux** — the other leading
GitOps engine — so you can compare the two on an identical workload. You'll need
the same prerequisites as Module 3:

* Docker
* `kind` and `kubectl`
* A GitHub account
* `flux` (installed below)

### The cluster

Flux and ArgoCD both want to own the cluster, so start Module 4 on a clean one.
Reset the local `kind` cluster from Module 3:

```bash
kind delete cluster --name gitops-demo
kind create cluster --config exercises/exercise-2/kind-config.yaml
kubectl get nodes
```

## Flux: the GitOps Toolkit

Flux reaches the same end state as ArgoCD — podinfo running and kept matching Git
— but through a toolkit of small, single-purpose controllers rather than one
Application object and a console. The reconciliation philosophy is identical:
pull from Git, converge continuously, correct drift. The difference is that the
moving parts are exposed as custom resources you commit.

### Step 1: Install the CLI and check the cluster

```bash
curl -s https://fluxcd.io/install.sh | sudo bash
flux check --pre
```

### Step 2: Bootstrap Flux into a Git repo

Flux *bootstraps* itself by committing its own controllers into a Git repository,
then configuring the cluster to sync from that repo. We can use the same GitHub
PAT you created in Module 3 — we re-export it here just to be sure.

```bash
export GITHUB_USER=you
export GITHUB_REPO=your-repo
export GIT_TOKEN=ghp_your_token
```

Now the install:

```bash
flux bootstrap github --owner=$GITHUB_USER --repository=$GITHUB_REPO --branch=main --path=clusters/my-cluster --personal
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
flux get sources helm
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
| Time to first deploy | Fast once bootstrapped: a template installs a self-managing ArgoCD, then add a root + child Applications (app-of-apps) | Moderate: bootstrap writes Flux into a Git repo first, then add a source plus a Kustomization or HelmRelease |
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

* Flux Getting Started & CLI — fluxcd.io/flux/get-started/ and fluxcd.io/flux/cmd/
* Flux Helm guide (HelmRepository + HelmRelease) — fluxcd.io/flux/guides/helmreleases/
* podinfo sample app & Helm chart — github.com/stefanprodan/podinfo · Helm repo: stefanprodan.github.io/podinfo
