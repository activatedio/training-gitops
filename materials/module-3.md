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

This exercise needs a `kind` cluster prepared for an ingress controller — the
`kind-config.yaml` in the exercise maps the host's ports 80/443 onto a node and
labels it `ingress-ready`. Create it:

```bash
kind create cluster --config exercises/exercise-2/kind-config.yaml
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
install is identical everywhere. Add it as an ApplicationSet at
`roots/cluster-addons/sealed-secrets.yaml`:

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
        repoURL: https://bitnami.github.io/sealed-secrets
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

## Installing an ingress controller

So far we'd reach ArgoCD and podinfo with `kubectl port-forward`. Before we deploy
a workload, let's stand up an **ingress controller** as a cluster-addon, so apps
get real URLs from the start. Our kind cluster is already prepared for this — the
Module 1 config maps the host's ports 80/443 onto a node and labels it
`ingress-ready`.

Unlike sealed-secrets, we **don't** want an ingress controller on every connected
cluster — that's a per-cluster decision. So instead of a `clusters` generator we
use a **git files generator**: the ApplicationSet only creates an Application for
clusters that have an opt-in config file under `cluster-configs/<cluster>/`. Here
we opt in just the local cluster.

`roots/cluster-addons/ingress-nginx.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: ingress-nginx
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: [missingkey=error]
  generators:
    - git:
        repoURL: https://github.com/you/your-gitops-repo
        revision: HEAD
        files:
          - path: roots/cluster-addons/cluster-configs/*/ingress-nginx.yaml
  template:
    metadata:
      name: 'ingress-nginx-{{.path.basename}}'
      namespace: argocd
    spec:
      project: cluster-addons
      source:
        repoURL: https://kubernetes.github.io/ingress-nginx
        chart: ingress-nginx
        targetRevision: '{{.chartVersion}}'
        helm:
          releaseName: ingress-nginx
          values: |
            {{- toYaml .values | nindent 12 }}
      destination:
        name: '{{.path.basename}}'
        namespace: ingress-nginx
      syncPolicy:
        automated: { prune: true, selfHeal: true }
        syncOptions: [ServerSideApply=true, CreateNamespace=true]
```

The generator scans `cluster-configs/*/ingress-nginx.yaml`; each match becomes one
Application named after its directory — the cluster's ArgoCD name — and deployed to
that cluster via `destination.name`. Opt the local cluster in with a config file;
`in-cluster` is ArgoCD's name for the cluster it runs on:

`roots/cluster-addons/cluster-configs/in-cluster/ingress-nginx.yaml`

```yaml
chartVersion: 4.12.1
values:
  controller:
    hostPort:
      enabled: true            # bind node 80/443; kind's port-mappings reach it
    service:
      type: ClusterIP
    nodeSelector:
      ingress-ready: "true"
    tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Equal
        effect: NoSchedule
    extraArgs:
      enable-ssl-passthrough: "true"   # lets the ArgoCD Ingress pass TLS through
    admissionWebhooks:
      enabled: false
```

To bring the controller up on another cluster later you'd just add
`cluster-configs/<that-cluster>/ingress-nginx.yaml` — no change to the
ApplicationSet. Commit and push:

```bash
git add roots/cluster-addons/ingress-nginx.yaml roots/cluster-addons/cluster-configs
git commit -m "ingress-nginx for in-cluster" && git push
```

(The `cluster-addons-root` syncs the top of `roots/cluster-addons/` but not the
`cluster-configs/` subdirectory — those files are generator *inputs*, not
manifests to apply directly.)

### Route the ArgoCD UI through the ingress

argocd-server serves HTTPS, so we use nginx's **SSL passthrough** — the controller
hands the TLS connection straight to argocd-server, no `server.insecure` needed
(your HTTPS `port-forward` keeps working too). Add an `Ingress` as a
cluster-resource; dropping it in `cluster-resources/in-cluster/` lets the
`cluster-resources` ApplicationSet sync it into the `argocd` namespace:

`cluster-resources/in-cluster/argocd-server-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
spec:
  ingressClassName: nginx
  rules:
    - host: argocd.localtest.me
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port: { number: 443 }
```

```bash
git add cluster-resources/in-cluster/argocd-server-ingress.yaml
git commit -m "expose argocd via ingress" && git push
```

`*.localtest.me` resolves to `127.0.0.1` and kind forwards your host's 80/443 to
the controller, so once it syncs the ArgoCD UI is at **https://argocd.localtest.me**
(accept the self-signed cert warning). Next we'll deploy podinfo with its own
ingress, reachable the same way.

## Create an "example" project and deploy podinfo

Workloads get their own **project** — an `AppProject` that scopes what they may
deploy — and enter through the **app-of-apps roots** pattern. We'll create an
`example` project, with its own root, and run podinfo in it.

First the project and its root. `projects/example.yaml` holds the `example`
`AppProject` plus an `example-root` Application (in that project) that syncs the
`roots/example/` directory. The `root` Application picks this up because it syncs
`projects/`. Point `repoURL` at your repo:

`projects/example.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: example
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  description: example workloads
  sourceRepos: ['*']
  destinations:
    - { namespace: '*', server: '*' }
  clusterResourceWhitelist:
    - { group: '*', kind: '*' }
  namespaceResourceWhitelist:
    - { group: '*', kind: '*' }
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: example-root
  namespace: argocd
spec:
  project: example
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

Then the workload — podinfo, pulled straight from its **Helm repository** (nothing
vendored), running in the `example` project. Since the ingress controller is
already up, we turn on the chart's ingress out of the gate so podinfo is reachable
at a real URL:

`roots/example/podinfo.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: podinfo
  namespace: argocd
spec:
  project: example
  source:
    repoURL: https://stefanprodan.github.io/podinfo
    chart: podinfo
    targetRevision: 6.14.0
    helm:
      releaseName: podinfo
      valuesObject:
        ui:
          message: "Deployed by GitOps"
        ingress:
          enabled: true
          className: nginx
          hosts:
            - host: podinfo.localtest.me
              paths:
                - path: /
                  pathType: ImplementationSpecific
  destination:
    server: https://kubernetes.default.svc
    namespace: podinfo
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions: [ServerSideApply=true, CreateNamespace=true]
```

Commit and push:

```bash
git add projects/example.yaml roots/example/podinfo.yaml
git commit -m "add example project + podinfo" && git push
```

Watch the chain in the UI: `root` applies your `example` project and its
`example-root`, `example-root` applies the `podinfo` Application, and `podinfo`
pulls the chart from its Helm repository and deploys it to the `podinfo`
namespace. That's app-of-apps — a root is just an Application whose children are
more Applications, all scoped to the `example` project. Because we enabled the
chart's ingress, podinfo is reachable at **http://podinfo.localtest.me** — no
port-forward. To change podinfo later, edit `roots/example/podinfo.yaml` (e.g.
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
