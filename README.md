# GitOps for Kubernetes

A short, hands-on course on managing Kubernetes clusters the GitOps way. It
starts from the one idea everything rests on — the **control loop** — builds up
through Kubernetes resources and Helm packaging, and finishes by deploying the
same application two ways with **ArgoCD** and **Flux**.

> 📹 Video walkthroughs to accompany each module are coming. This repo holds the
> written material and the runnable exercises in the meantime.

## Who this is for

Engineers who can use `kubectl` against a cluster and want to understand *why*
GitOps fits Kubernetes so naturally — and how to put it into practice with the
two leading controllers.

## Prerequisites

- A local Kubernetes cluster ([kind](https://kind.sigs.k8s.io/),
  [k3d](https://k3d.io/), or Docker Desktop) and `kubectl` pointed at it
- `git`
- For Module 3 (both the ArgoCD and Flux walkthroughs): a GitHub account, a Git
  repo you control, and a Personal Access Token with `repo` scope

## Modules

| # | Module | Reading | Exercises |
|---|--------|---------|-----------|
| 1 | **The Control Loop** — essential Kubernetes: clusters, etcd/API server, and how Deployment → ReplicaSet → Pod is a chain of closed loops | [materials/module-1.md](materials/module-1.md) | [exercises/module1](exercises/module1) |
| 2 | **Resources and Helm Charts** — the wider set of resource kinds, why raw manifests don't scale, Helm as packaging, and Git as the setpoint | [materials/module-2.md](materials/module-2.md) | — |
| 3 | **Hands-On: ArgoCD and Flux** — deploy the canonical guestbook app two ways and compare the tools on an identical workload | [materials/module-3.md](materials/module-3.md) | [exercises/module3](exercises/module3) |

## Hands-on exercises

### Module 1 — watch the control loop converge

A guided `demo.sh` that creates a 3-node `kind` cluster, declares a Deployment,
and lets you watch the controllers reconcile desired state — including deleting
a Pod and watching the ReplicaSet replace it.

```bash
cd exercises/module1
chmod +x demo.sh
./demo.sh
```

See [exercises/module1](exercises/module1).

### Module 3 — ArgoCD and Flux walkthroughs

Standalone, commented scripts for both the ArgoCD and Flux paths, deploying the
same guestbook app. The ArgoCD path is GitOps-first: bootstrap a self-managing
ArgoCD from the [`activatedio/argocd-bootstrap`](https://github.com/activatedio/argocd-bootstrap)
template, then ship and change the guestbook entirely through Git and the UI.
Full instructions are in
[exercises/module3/README.md](exercises/module3/README.md).

```bash
cd exercises/module3
chmod +x argocd/*.sh flux/*.sh
```

## Repository layout

```
training/
├── README.md            # you are here
├── materials/           # course reading (Markdown), one file per module
│   ├── module-1.md
│   ├── module-2.md
│   └── module-3.md
└── exercises/           # runnable hands-on material
    ├── module1/         # control-loop demo (kind + kubectl)
    └── module3/         # ArgoCD and Flux walkthroughs
```

## Further reading

- ArgoCD — [Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/) · [Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
- Flux — [Getting Started](https://fluxcd.io/flux/get-started/) · [CLI reference](https://fluxcd.io/flux/cmd/)
- [Helm](https://helm.sh/docs/) · [Kind](https://kind.sigs.k8s.io/) · [Kubernetes docs](https://kubernetes.io/docs/)
- Example app — [argocd-example-apps](https://github.com/argoproj/argocd-example-apps) (path: `guestbook`)
