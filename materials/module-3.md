# Module 3 – Hands-On: ArgoCD

## Introduction

Let's use GitOps to deploy [podinfo](https://github.com/stefanprodan/podinfo) —
a small web app published as a Helm chart — to a Kubernetes cluster with ArgoCD.
In [Module 4](module-4.md) we will do the same with Flux so you can compare.

To follow along, you will need:

* Docker
* `kind` and `kubectl`
* A GitHub account
* And Make

Kind and kubectl can be installed with Homebrew on a Mac.

### The cluster

We'll reuse the same local `kind` cluster from Module 1. If it's still running
you're set — `kubectl get nodes` should list the `gitops-demo` control-plane and
two workers. If you tore it down (or skipped Module 1), recreate it from the
config in the exercises:

```bash
kind create cluster --config exercises/module-1/kind-config.yaml
kubectl get nodes      # the gitops-demo control-plane + 2 workers
```

`kind delete cluster --name gitops-demo` removes it again when you're done.

## ArgoCD: bootstrap once, then drive everything from Git

Let's start by installing ArgoCD using a GitOps approach similar to the popular
argocd-autopilot project. In fact, feel free to use that project as a starting
point for your own ArgoCD install.

We start from a small **bootstrap template** `github.com/activatedio/argocd-bootstrap` that installs an ArgoCD instance which
*manages itself from Git*. After that you can push changes to the Git repository
to manage the ArgoCD installation.


### Clone the template into a repo you control

First, clone the template and push into a repo you control.

```bash
git clone https://github.com/activatedio/argocd-bootstrap
cd argocd-bootstrap
git remote set-url origin https://github.com/you/your-gitops-repo
git push -u origin main
```

### Render the templates, push, then install

While we will use a Git repository to manage the ArgoCD installation, we need to
bootstrap it with local manifests that contain the correct values for our
installation and are in sync with the referenced repository on GitHub.

These steps make use of Make, which you can install with any package manager, including Homebrew on a Mac. If you really don't want to use Make, you can just run the commands directly.

First, create a GitHub Personal Access Token (PAT) with the `repo` scope. Then
export it along with the repo URL and version of ArgoCD you want to install.

```bash
export GIT_REPO=https://github.com/you/your-gitops-repo
export GIT_TOKEN=ghp_your_token
export ARGOCD_VERSION=v3.2.12
```

Render the templates and publish them. This only edits files in your repo;
nothing is applied to the cluster yet.

```bash
make init      # bakes GIT_REPO + ARGOCD_VERSION into the manifests
git commit -am "init gitops repo" && git push
```

Now install. 

This creates the repo-access secret, applies the main ArgoCD manifest, waits for
ArgoCD to come up, and then bootstraps self-management: the `argo-cd` and `root`
Applications, the `cluster-resources` ApplicationSet, and the projects under
`projects/` (`default`, `roots`, `cluster-addons`).

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
Applications and the `cluster-resources` ApplicationSet, all Synced. No
workloads yet — we add those next.

## An opinionated approach to ArgoCD

I have used ArgoCD for some time and have developed my opinion on how to set it
up. You are welcome to follow my approach or use it as a starting point for your
own.

To understand my approach, you should know:

1. I don't like scaffolding tools that generate manifests from commands, so I
   don't use argocd-autopilot to set up apps and projects. Instead I create the
   manifests myself.
2. I prefer to use ArgoCD declaratively from Git, or via the UI. I rarely use
   the argocd command line.
3. I avoid Kustomize, as I find it difficult to understand and clunky to use.
4. I separate my installs into three large buckets: **ops** for internal
   tools; **non-prod** for workloads not in production, like test environments;
   and **prod** for, well, production apps.
5. Where I see repeated installs across many environments, I reach for an
   ApplicationSet.

In short, the layers I install are:

* cluster-resources
* roots
* cluster-addons
* workload specific roots


The argocd-bootstrap template contains a standard ArgoCD bootstrap install along
with an ApplicationSet for "cluster-resources". Cluster resources are simple
manifests that are applied to the cluster.  I will often use them for storage
classes and other cluster-wide resources that don't fit neatly into another
deployment system.

After cluster resources, I have a "roots" project that is the starting point for all installations. The first use of a "roots" application is a "cluster-addons" application that uses ApplicationSets to install add-ons onto any managed cluster.
My first cluster add-on is sealed secrets, which I set up with a simple
generator that installs it onto any connected cluster. I also use cluster
add-ons for installations like:

* external-dns
* cert-manager
* prometheus

I then follow this same pattern to install projects and roots for my workloads
across environments. In this example we won't get into a specific environment
strategy; we'll just create a single "example" root and install a single
application into it.

## Deploying sealed secrets as a cluster-addon

Secrets are the awkward part of GitOps. Everything else is happy to live in Git,
but you can't commit a plaintext `Secret` to a repository. **Sealed Secrets**
(from Bitnami) solves this. A controller running in the cluster holds a private
key; you encrypt your secret against its public key with the `kubeseal` CLI,
producing a `SealedSecret` custom resource that is safe to commit — only that
controller can decrypt it. The controller watches for `SealedSecret`s and
unseals each one into an ordinary `Secret` in the same namespace. So the
encrypted form lives in Git and the plaintext only ever exists inside the
cluster.

That makes it an ideal cluster-addon: every cluster needs the controller, and the
install is identical everywhere. The template ships it as a commented
ApplicationSet at `roots/cluster-addons/sealed-secrets.yaml` — uncomment it:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: sealed-secrets
  namespace: argocd
spec:
  generators:
    - clusters: {}            # every cluster registered with ArgoCD
  template:
    metadata:
      name: 'sealed-secrets-{{name}}'
      namespace: argocd
    spec:
      project: cluster-addons
      source:
        repoURL: https://bitnami-labs.github.io/sealed-secrets
        chart: sealed-secrets
        targetRevision: 2.17.4
        helm:
          releaseName: sealed-secrets
      destination:
        server: '{{server}}'
        namespace: kube-system
      syncPolicy:
        automated: { prune: true, selfHeal: true }
        syncOptions: [ServerSideApply=true, CreateNamespace=true]
```

The `clusters` generator is the key idea: it produces one Application per cluster
registered with ArgoCD (including the in-cluster control plane), so this single
file installs sealed-secrets *everywhere* — register a new cluster later and it
gets the controller automatically. Every generated Application runs in the
`cluster-addons` project, and the `cluster-addons-root` (already live from the
bootstrap) syncs whatever it finds under `roots/cluster-addons/`. Commit and
push:

```bash
git add roots/cluster-addons/sealed-secrets.yaml
git commit -m "add sealed-secrets cluster-addon" && git push
```

On its next poll the `cluster-addons-root` picks it up and the controller comes
up in `kube-system`. From then on the workflow is: `kubeseal` a secret into a
`SealedSecret`, commit that next to the app that needs it, and the controller
unseals it in the cluster — no plaintext ever leaves your machine.

## Build an "example" root and deploy podinfo

Workloads enter through the **app-of-apps roots** pattern. We'll stand up a new
`example` root from scratch: a child Application for podinfo, plus a root
Application that points at the folder holding it.

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

Watch the chain in the UI: `root` applies your new `example-root`,
`example-root` applies the `podinfo` Application, and `podinfo` pulls the chart
from its Helm repository and deploys it to the `podinfo` namespace. That's
app-of-apps — a root is just an Application whose children are more
Applications. To change podinfo later, edit `roots/example/podinfo.yaml` (e.g.
bump `targetRevision`), commit, and ArgoCD shows the diff before it syncs.

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
