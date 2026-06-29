# GitOps for Kubernetes

A short course with exercises on managing Kubernetes clusters the GitOps way. It covers the concept of a closed control
loop, Kubernetes resources and Helm packaging, and walks through deploying a sample app with **ArgoCD** and **Flux**.

## Prerequisites

- Docker to run a kind cluster.
- `git`
- A GitHub account, including a repo and Personal Access Token with `repo` scope.

## Modules

| # | Module | Reading | Exercises |
|---|--------|---------|-----------|
| 1 | **The Control Loop** — essential Kubernetes: clusters, etcd/API server, and how Deployment → ReplicaSet → Pod is a chain of closed loops | [materials/module-1.md](materials/module-1.md) | [exercises/module-1](exercises/module-1) |
| 2 | **Resources and Helm Charts** — the wider set of resource kinds, why raw manifests don't scale, Helm as packaging, and Git as the setpoint | [materials/module-2.md](materials/module-2.md) | — |
| 3 | **Hands-On: ArgoCD and Flux** — deploy the canonical guestbook app two ways and compare the tools on an identical workload | [materials/module-3.md](materials/module-3.md) | [exercises/module-3](exercises/module-3) |

## Repository layout

```
training/
├── README.md            # you are here
├── materials/           # course reading (Markdown), one file per module
│   ├── module-1.md
│   ├── module-2.md
│   └── module-3.md
└── exercises/           # runnable hands-on material
    ├── module-1/        # control-loop demo (kind + kubectl)
    └── module-3/        # ArgoCD and Flux walkthroughs
```

## Further reading

- ArgoCD — [Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/) · [Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
- Flux — [Getting Started](https://fluxcd.io/flux/get-started/) · [CLI reference](https://fluxcd.io/flux/cmd/)
- [Helm](https://helm.sh/docs/) · [Kind](https://kind.sigs.k8s.io/) · [Kubernetes docs](https://kubernetes.io/docs/)
- Example app — [argocd-example-apps](https://github.com/argoproj/argocd-example-apps) (path: `guestbook`)
