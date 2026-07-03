# Exercise 2 — GitOps with ArgoCD

A hands-on walk through deploying the podinfo application using ArgoCD.

## Prerequisites

- [`kind`](https://kind.sigs.k8s.io/), `kubectl`, `git`, and `make`
- Docker (or another runtime kind supports) running
- A **Git repo you control** for the manifests, plus a GitHub PAT with the
  `repo` scope

## Create the cluster

```bash
kind create cluster --config kind-config.yaml
kubectl get nodes -o wide
```

## Bootstrap a self-managing ArgoCD

Clone the template and point it at your repo:

```bash
git clone https://github.com/activatedio/argocd-bootstrap
cd argocd-bootstrap
git remote set-url origin https://github.com/you/your-gitops-repo
git push -u origin main
```

Export the values the template renders in (create a GitHub PAT with the `repo`
scope first):

```bash
export GIT_REPO=https://github.com/you/your-gitops-repo
export GIT_TOKEN=ghp_your_token
export ARGOCD_VERSION=v3.2.12
```

Render the manifests and publish them — this only edits files, nothing hits the
cluster yet, so ArgoCD's first reconcile is already in sync:

```bash
make init
git commit -am "init gitops repo" && git push
```

Now install: repo secret + ArgoCD + self-management (the `argo-cd` and `root`
Applications, the `cluster-resources` ApplicationSet, and the `default` / `roots`
/ `cluster-addons` projects):

```bash
make install
```

## Open the UI

```bash
make password        # prints the initial admin password (user: admin)
make port-forward    # forwards the console to https://localhost:8080 (blocks)
```

Leave `port-forward` running in its own terminal and open
**https://localhost:8080**. You'll see the control plane managing itself — no
workloads yet.

> In the remaining steps you **create files in your cloned `argocd-bootstrap`
> repo**, then commit and push. Stay in the `argocd-bootstrap` directory (from
> step 2) so the paths below are relative to the repo root, and wherever you see
> `https://github.com/you/your-gitops-repo`, use your own repo URL.

## Install an ingress controller

Install ingress so we can reach the ArgoCD UI and podinfo once they're installed.
This uses a git files generator that installs only where a configuration file
exists; we provide one for `in-cluster`.

Create the ApplicationSet at `roots/cluster-addons/ingress-nginx.yaml` and set
`repoURL` under the git generator to your repo.

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
        syncOptions: [ServerSideApply=true, CreateNamespace=true]
```

Configure the local cluster to use this by creating the file `roots/cluster-addons/cluster-configs/in-cluster/ingress-nginx.yaml`.

```yaml
chartVersion: 4.12.1
values:
  controller:
    hostPort:
      enabled: true
    service:
      type: ClusterIP
    nodeSelector:
      ingress-ready: "true"
    tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Equal
        effect: NoSchedule
    extraArgs:
      enable-ssl-passthrough: "true"
    admissionWebhooks:
      enabled: false
```

Then expose the ArgoCD UI through the ingress with an SSL-passthrough `Ingress`,
applied via the `cluster-resources` ApplicationSet. Create
`cluster-resources/in-cluster/argocd-server-ingress.yaml`:

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
                port:
                  number: 443
```

Commit and push:

```bash
git add -A
git commit -m "install ingress-nginx (in-cluster) + expose argocd" && git push
```

`*.localtest.me` resolves to `127.0.0.1` and kind forwards 80/443, so once it
syncs the ArgoCD UI is available at **https://argocd.localtest.me**.

## Create the `example` project and deploy podinfo

Now we will install the podinfo application into its own project using an
Application. First, create `projects/example.yaml` with the `example` project and
its root application (the `root` Application syncs `projects/`, so it applies
this):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: example
  namespace: argocd
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

Then the workload — create `roots/example/podinfo.yaml`. It references the
podinfo Helm repo directly and configures the ingress.

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
    syncOptions: [ServerSideApply=true, CreateNamespace=true]
```

Commit and push:

```bash
git add -A
git commit -m "add example project + podinfo" && git push
```

View the root and sync the podinfo application in the UI. Once synced,
podinfo is at **http://podinfo.localtest.me**.

## Change something and watch it sync

Now let's change a value, view the diff in the ArgoCD UI, and then sync to see the
change made live.

In `roots/example/podinfo.yaml`, change the `ui.message` value to anything you
like.

```bash
git commit -am "podinfo: change ui.message" && git push
```

Open podinfo in the UI and review the **App Diff** panel.

## Clean up

Tear down the whole cluster when you're done:

```bash
kind delete cluster --name gitops-demo
```

## Sources

- argocd-bootstrap template — https://github.com/activatedio/argocd-bootstrap
- ArgoCD Declarative Setup, ApplicationSet & app-of-apps —
  https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/,
  /operator-manual/applicationset/, /operator-manual/cluster-bootstrapping/
- podinfo sample app & Helm chart — https://github.com/stefanprodan/podinfo
  (Helm repo: https://stefanprodan.github.io/podinfo)
