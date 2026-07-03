# GitOps for Kubernetes

A short course with exercises on managing Kubernetes clusters the GitOps way. It
covers the concept of a closed control loop, Kubernetes resources and Helm
packaging, and walks through deploying a sample app with **ArgoCD**.

## Prerequisites

- Docker to run a kind cluster
- `kind` and `kubectl`
- `git` and `make`
- A GitHub account, with a repo and a Personal Access Token (`repo` scope) for
  Exercise 2

## Modules

| # | Module | Reading | Exercise |
|---|--------|---------|----------|
| 1 | **The Control Loop** — essential Kubernetes: clusters, etcd/API server, and how Deployment → ReplicaSet → Pod is a chain of closed loops | [materials/module-1.md](materials/module-1.md) | [exercises/exercise-1](exercises/exercise-1) |
| 2 | **Resources, Helm Charts & ArgoCD** — the wider set of resource kinds, Helm as packaging, GitOps as the reconciliation model, and a hands-on ArgoCD deploy of the podinfo app | [materials/module-2.md](materials/module-2.md) | [exercises/exercise-2](exercises/exercise-2) |

## Repository layout

```
training-gitops/
├── README.md            # you are here
├── materials/           # course reading (Markdown), one file per module
│   ├── module-1.md
│   └── module-2.md
└── exercises/           # runnable hands-on material
    ├── exercise-1/      # control-loop demo (kind + kubectl)
    └── exercise-2/      # ArgoCD GitOps walkthrough
```

## Further reading

- ArgoCD — [Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/) · [Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
- [Helm](https://helm.sh/docs/) · [Kind](https://kind.sigs.k8s.io/) · [Kubernetes docs](https://kubernetes.io/docs/)
- Example app — [podinfo](https://github.com/stefanprodan/podinfo) (Helm repo: `https://stefanprodan.github.io/podinfo`)
