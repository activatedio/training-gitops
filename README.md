# GitOps for Kubernetes

A short course with exercises on managing Kubernetes clusters the GitOps way. It covers the concept of a closed control
loop, Kubernetes resources and Helm packaging, and walks through deploying a sample app with **ArgoCD** and **Flux**.

## Prerequisites

- Docker to run a kind cluster.
- `git`
- `kind`
- Access to a GitHub account.

## Modules

| # | Module | Reading | Exercises |
|---|--------|---------|-----------|
| 1 | **The Control Loop** — essential Kubernetes: clusters, etcd/API server, and how Deployment → ReplicaSet → Pod is a chain of closed loops | [materials/module-1.md](materials/module-1.md) | [exercises/exercise-1](exercises/exercise-1) |
| 2 | **Resources and Helm Charts** — the wider set of resource kinds, why raw manifests don't scale, Helm as packaging, and Git as the setpoint | [materials/module-2.md](materials/module-2.md) | — |
| 3 | **Hands-On: ArgoCD** — bootstrap a self-managing ArgoCD and deploy the podinfo app via the app-of-apps roots pattern | [materials/module-3.md](materials/module-3.md) | [exercises/exercise-2](exercises/exercise-2) |
| 4 | **Hands-On: Flux** — deploy the same podinfo app with Flux, then compare the two engines side by side | [materials/module-4.md](materials/module-4.md) | [exercises/module-4](exercises/module-4) |

## Repository layout

```
training/
├── README.md            # you are here
├── materials/           # course reading (Markdown), one file per module
│   ├── module-1.md
│   ├── module-2.md
│   ├── module-3.md
│   └── module-4.md
└── exercises/           # runnable hands-on material
    ├── exercise-1/      # control-loop demo (kind + kubectl)
    ├── exercise-2/      # ArgoCD walkthrough
    └── module-4/        # Flux walkthrough
```

## Further reading

- ArgoCD — [Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/) · [Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
- Flux — [Getting Started](https://fluxcd.io/flux/get-started/) · [CLI reference](https://fluxcd.io/flux/cmd/)
- [Helm](https://helm.sh/docs/) · [Kind](https://kind.sigs.k8s.io/) · [Kubernetes docs](https://kubernetes.io/docs/)
- Example app — [podinfo](https://github.com/stefanprodan/podinfo) (Helm repo: `https://stefanprodan.github.io/podinfo`)
