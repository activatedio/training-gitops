# GitOps for Kubernetes — Module 4 Scripts (Flux)

Hands-on command scripts for **Module 4: Flux**. They deploy the same
[**podinfo**](https://github.com/stefanprodan/podinfo) app as Module 3, but with
**Flux** — pulled from its **Helm repository**
(`https://stefanprodan.github.io/podinfo`) via a `HelmRepository` source and a
`HelmRelease`, reconciled by the helm-controller.

> ArgoCD deploys the same app in **Module 3** ([exercises/module-3](../module-3)).

## Prerequisites

- A running Kubernetes cluster (local `kind`). Start Module 4 on a clean cluster
  — ArgoCD and Flux both want to own it.
- `kubectl` pointed at that cluster
- `git`, and `flux` (installed by `01-install-cli.sh`)
- A **GitHub account** and a Personal Access Token with `repo` scope (Flux
  bootstrap commits its controllers into a repo you control).

## Layout

```
module-4/
├── README.md
└── flux/
    ├── 01-install-cli.sh        # install flux CLI + pre-flight check
    ├── 02-bootstrap.sh          # bootstrap Flux into a Git repo
    ├── 03-create-source.sh      # declare the HelmRepository source (podinfo)
    ├── 04-create-helmrelease.sh # declare the HelmRelease (helm-controller) + commit
    └── 05-observe.sh            # CLI observability (get / reconcile / logs)
```

## How to run

Make the scripts executable, then edit the placeholder variables at the top of
`flux/02-bootstrap.sh` (`GITHUB_USER`, `GITHUB_TOKEN`, repo name, path).

```bash
chmod +x flux/*.sh
./flux/01-install-cli.sh
./flux/02-bootstrap.sh
./flux/03-create-source.sh
./flux/04-create-helmrelease.sh
./flux/05-observe.sh
```

## Notes

- `flux bootstrap` commits Flux's own controllers into your Git repo — this is
  intentional ("Flux manages Flux the GitOps way").
- podinfo is deployed from its Helm repository, nothing vendored: a
  `HelmRepository` source + `HelmRelease` handled by the helm-controller.
- To move podinfo to a new chart release, bump `--chart-version` in
  `04-create-helmrelease.sh` (then re-run / commit the regenerated HelmRelease).

## Sources

- Flux Getting Started & CLI — https://fluxcd.io/flux/get-started/ and https://fluxcd.io/flux/cmd/
- Flux Helm guide (HelmRepository + HelmRelease) — https://fluxcd.io/flux/guides/helmreleases/
- podinfo sample app & Helm chart — https://github.com/stefanprodan/podinfo (Helm repo: https://stefanprodan.github.io/podinfo)
```
