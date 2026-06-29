# Module 3 – Hands-On: ArgoCD

## Introduction

Let's use GitOps to deploy [podinfo](https://github.com/stefanprodan/podinfo) —
a small web app published as a Helm chart — to a Kubernetes cluster with ArgoCD.
([Module 4](module-4.md) deploys the same app with Flux, so you can compare the
two.) To follow along, you will need:

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

## ArgoCD: bootstrap once, then drive everything from Git

Let's start by installing ArgoCD using a GitOps approach similar to the popular argocd-autopilot project. In fact, feel free to use that project as a starting point for your own ArgoCD install.

We start from a small **bootstrap template** `github.com/activatedio/argocd-bootstrap` that installs an ArgoCD instance which
*manages itself from Git*. After that you can push changes to the Git repoisitory to manage the ArgoCD installation.

The template's layout follows [argocd-autopilot](https://github.com/argoproj-labs/argocd-autopilot)
— `bootstrap/` + `projects/` + a `cluster-resources` ApplicationSet — applied
directly with `kubectl`, no autopilot CLI. The bootstrap wires up:

1. An `argo-cd` Application that syncs ArgoCD's own install.
2. A `root` Application that manages the projects under `projects/`: `default`,
   `roots`, and `cluster-addons`.
3. A `cluster-resources` ApplicationSet (in the **default** project) for
   cluster-scoped resources (the `in-cluster` folder = the cluster ArgoCD runs in).
4. The **roots** project — app-of-apps roots. Each root Application points at a
   directory under `roots/` and fans out into child Applications. A live
   `cluster-addons-root` is the in-repo example.
5. The **cluster-addons** project — scopes add-ons synced to every cluster. It
   ships unpopulated, with a commented `sealed-secrets` example showing the pattern.

Workloads arrive through the roots pattern. Below we'll build an `example` root from
scratch and let it deploy podinfo.

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

Now install. 

This creates the repo-access secret, applies the main ArgoCD manifest, waits for ArgoCD to come up, and then bootstraps self-management: the `argo-cd` and `root` Applications, the `cluster-resources` ApplicationSet, and the projects under `projects/` (`default`, `roots`, `cluster-addons`).

```bash
make install   # repo secret + ArgoCD install + self-management
```

### Open the UI

```bash
make password        # prints the initial admin password (user: admin)
make port-forward    # forwards the console to https://localhost:8080
```

Open http://localhost:8080 in your browser, log in, and you'll see the control
plane managing itself: the `argo-cd`, `root`, and `cluster-addons-root`
Applications and the `cluster-resources` ApplicationSet, all Synced. No workloads
yet — we add those next.

### Build an "example" root and deploy podinfo

Workloads enter through the **app-of-apps roots** pattern. We'll stand up a new
`example` root from scratch: a child Application for podinfo, plus a root Application
that points at the folder holding it.

First, the child — podinfo, pulled straight from its **Helm repository** (nothing
vendored). This is a normal ArgoCD `Application` whose source is the chart:

`roots/example/podinfo.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: podinfo
  namespace: argocd
spec:
  project: roots
  source:
    repoURL: https://stefanprodan.github.io/podinfo
    chart: podinfo
    targetRevision: 6.14.0
    helm:
      releaseName: podinfo
      valuesObject:
        ui:
          message: "Deployed by GitOps"
  destination:
    server: https://kubernetes.default.svc
    namespace: podinfo
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions: [ServerSideApply=true, CreateNamespace=true]
```

Then the root — an `example-root` Application (in the `roots` project) that syncs the
`roots/example/` directory. Add it to `projects/roots.yaml` (next to
`cluster-addons-root`), pointing `repoURL` at your repo:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: example-root
  namespace: argocd
spec:
  project: roots
  source:
    repoURL: https://github.com/you/your-gitops-repo
    path: roots/example
    targetRevision: HEAD
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions: [ServerSideApply=true, CreateNamespace=true]
```

Commit and push:

```bash
git add roots/example/podinfo.yaml projects/roots.yaml
git commit -m "add example root + podinfo" && git push
```

Watch the chain in the UI: `root` applies your new `example-root`, `example-root` applies
the `podinfo` Application, and `podinfo` pulls the chart from its Helm repository
and deploys it to the `podinfo` namespace. That's app-of-apps — a root is just an
Application whose children are more Applications. To change podinfo later, edit
`roots/example/podinfo.yaml` (e.g. bump `targetRevision`), commit, and ArgoCD shows
the diff before it syncs.

### Wrap-up

That's ArgoCD, GitOps-first: a template installs an ArgoCD that manages itself,
projects scope what runs where, the `cluster-resources` ApplicationSet handles
cluster-scoped resources, and workloads arrive as app-of-apps roots — every
change a commit you review in the console, never an imperative command.

Next, [Module 4](module-4.md) deploys this same podinfo app with **Flux** and
compares the two engines side by side.

**Sources**

* argocd-bootstrap template — github.com/activatedio/argocd-bootstrap
* ArgoCD Declarative Setup, ApplicationSet & app-of-apps — argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/, /operator-manual/applicationset/, and /operator-manual/cluster-bootstrapping/
* podinfo sample app & Helm chart — github.com/stefanprodan/podinfo · Helm repo: stefanprodan.github.io/podinfo
