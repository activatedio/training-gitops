# GitOps for Kubernetes — Module 3 Scripts

Hands-on command scripts extracted from **Module 3: ArgoCD and Flux**.
Both walkthroughs deploy the same canonical **guestbook** app
(`github.com/argoproj/argocd-example-apps`, path `guestbook`) two different
ways so you can compare the tools on an identical workload.

## Prerequisites

- A running Kubernetes cluster (local `k3d`, `kind`, or Docker Desktop is fine)
- `kubectl` pointed at that cluster
- `git` (Flux walkthrough)
- For Flux bootstrap: a GitHub account and a Personal Access Token with `repo` scope

## Layout

```
module3-scripts/
├── README.md
├── argocd/
│   ├── 01-install.sh        # install ArgoCD into the cluster
│   ├── 02-access-ui.sh      # port-forward the UI + get admin password
│   ├── 03-create-app.sh     # create the guestbook Application (CLI form)
│   └── 04-sync.sh           # sync + optional automated sync policy
├── flux/
│   ├── 01-install-cli.sh    # install flux CLI + pre-flight check
│   ├── 02-bootstrap.sh      # bootstrap Flux into a Git repo
│   ├── 03-create-source.sh  # declare the GitRepository source
│   ├── 04-create-kustomization.sh  # declare the Kustomization + commit
│   └── 05-observe.sh        # CLI observability (get / reconcile / logs)
└── manifests/
    └── guestbook-application.yaml  # declarative ArgoCD Application CRD
```

## How to run

Each script is standalone and commented. Make them executable first:

```bash
chmod +x argocd/*.sh flux/*.sh
```

### ArgoCD path

```bash
./argocd/01-install.sh
./argocd/02-access-ui.sh        # leave the port-forward running in its own terminal
# either declarative:
kubectl apply -n argocd -f manifests/guestbook-application.yaml
# or imperative:
./argocd/03-create-app.sh
./argocd/04-sync.sh
```

### Flux path

Edit the placeholder variables at the top of `flux/02-bootstrap.sh`
(`GITHUB_USER`, `GITHUB_TOKEN`, repo name, path) before running.

```bash
./flux/01-install-cli.sh
./flux/02-bootstrap.sh
./flux/03-create-source.sh
./flux/04-create-kustomization.sh
./flux/05-observe.sh
```

## Notes

- The guestbook repo's default branch is `master`; the Flux source uses
  `--branch=master` to match. Adjust if upstream changes.
- Port-forwarding the ArgoCD UI is for local/demo use, not production.
- `flux bootstrap` commits Flux's own controllers into your Git repo — this is
  intentional ("Flux manages Flux the GitOps way").

## Sources

- ArgoCD Getting Started & Declarative Setup — https://argo-cd.readthedocs.io/en/stable/getting_started/ and https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/
- argocd app sync reference — https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_app_sync/
- Flux Getting Started & CLI — https://fluxcd.io/flux/get-started/ and https://fluxcd.io/flux/cmd/
- Guestbook example app — https://github.com/argoproj/argocd-example-apps (path: guestbook)
