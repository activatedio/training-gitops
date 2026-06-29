# Module 3 – Hands-On: ArgoCD and Flux

## Cold Open

In Module 2 we promised concrete examples. So let's deploy the same
application two ways. We'll take the classic guestbook app and hand it
to ArgoCD, then hand the very same job to Flux. Same Git repository,
same end state — a running guestbook in your cluster — but two very
different paths to get there. By the end you'll have typed the real
commands for both, seen where each one asks for your attention, and have
a table to help you pick the right tool for your stack.

One assumption before we start: you have a running cluster and kubectl
pointed at it. A local k3d, kind, or Docker Desktop cluster is perfect
for following along.

## The Plan: One App, Two Tools

The guestbook is a tiny two-tier web app — a front end and a Redis back
end — and it's the canonical GitOps demo. The Argo project publishes it
at github.com/argoproj/argocd-example-apps in a folder named guestbook,
as plain Kubernetes manifests. That single source of truth lets us
compare the tools fairly: the manifests never change, only the machinery
that delivers them.

Remember the shape difference from Module 2. ArgoCD wraps the whole app
in a single object — an Application — and gives you a console to sync
it. Flux assembles the same outcome from a chain of small controllers,
each reading a custom resource you commit to Git. Watch for that
contrast as we go.

## Walkthrough 1 — ArgoCD: the Application and the UI

ArgoCD runs inside the cluster as a set of components — an API server, a
repo server, and the application-controller that does the reconciling.
We install it, point it at the guestbook, and let it converge.

### Step 1: Install ArgoCD

Create a namespace and apply the upstream install manifest. This brings
up all of ArgoCD's components in the argocd namespace.

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# wait until every pod is Running
kubectl get pods -n argocd -w
```

### Step 2: Reach the UI and log in

The API server isn't exposed by default. Port-forward it, grab the
auto-generated admin password, and open the console in a browser.

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# initial admin password (username is "admin")
argocd admin initial-password -n argocd
# then visit https://localhost:8080 and log in
```

This is the moment ArgoCD differs most from Flux: you now have a
*graphical control plane*. Everything from here can be done by clicking,
or by the CLI — your choice.

### Step 3: Create the guestbook — declaratively

The cleanest, GitOps-native way is to declare an Application and apply
it. This is the CRD at the heart of ArgoCD: it names the source (repo,
path, revision) and the destination (cluster, namespace).

```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
destination:
  server: https://kubernetes.default.svc
  namespace: guestbook
```

```bash
kubectl apply -n argocd -f guestbook-application.yaml
```

### Step 4: Sync — the click that closes the loop

By default the app is created OutOfSync: ArgoCD knows the desired state
from Git but hasn't applied it yet. You converge it by syncing. In the
UI, you open the guestbook app, see the resource tree light up, and
press the Sync button. From the CLI:

```bash
argocd app sync guestbook
# watch it reach Synced / Healthy
argocd app get guestbook
```

Want it hands-off? Turn on automated sync so future Git commits apply
themselves, with optional self-heal and prune:

```bash
argocd app set guestbook --sync-policy automated --self-heal
--auto-prune
```

That's the whole ArgoCD story: one Application object, a resource tree
you can see, and a Sync that's either a click or an automated policy.
The UI is the headline feature — you literally watch the control loop
converge.

## Walkthrough 2 — Flux: the GitOps Toolkit

Flux reaches the same guestbook by composing small controllers. There's
no app-level object and no console; instead you commit custom resources
and let the toolkit reconcile them. The reconciliation philosophy is
identical to ArgoCD's — pull from Git, converge continuously — but the
moving parts are exposed.

### Step 1: Install the CLI and check the cluster

```bash
# install the flux CLI
curl -s https://fluxcd.io/install.sh | sudo bash
# verify the cluster can run Flux

flux check --pre
```

### Step 2: Bootstrap Flux into a Git repo

Here is the philosophical fork in the road. Flux *bootstraps* itself by
committing its own controllers into a Git repository, then configuring
the cluster to sync from that repo. Flux manages Flux the GitOps way.
You will need a GitHub token with repo scope.

export GITHUB_TOKEN=\<your-pat\>

flux bootstrap github \\

--owner=\$GITHUB_USER \\

--repository=fleet-infra \\

--branch=main \\

--path=clusters/my-cluster \\

--personal

This brings up the toolkit controllers in the flux-system namespace: the
source-controller, kustomize-controller, helm-controller, and
notification-controller. That hierarchy is the heart of Flux — each does
one job.

### Step 3: Declare the source

First tell Flux where the guestbook manifests live. A GitRepository
source is fetched by the source-controller on an interval.

```bash
flux create source git guestbook \
--url=https://github.com/argoproj/argocd-example-apps.git \
--branch=master \
--interval=1m \
--export > ./clusters/my-cluster/guestbook-source.yaml
```

### Step 4: Declare the Kustomization

Now point the kustomize-controller at the path inside that source. A
Kustomization applies the manifests and, with --prune, removes anything
you later delete from Git.

```bash
flux create kustomization guestbook \
  --source=GitRepository/guestbook \
  --path="./guestbook" \
  --prune=true \
  --target-namespace=guestbook \
  --interval=5m \
  --health-check="Deployment/guestbook-ui.guestbook" \
  --export > ./clusters/my-cluster/guestbook-kustomization.yaml
```

Commit both files. Because Flux is already syncing this repo, the moment
your commit lands the controllers pick it up and deploy the guestbook —
no extra apply needed.

```bash
git add -A && git commit -m "deploy guestbook" && git push
```

### Step 5: Observe — from the command line

Flux has no Sync button, so you watch with the CLI. You can also force
an immediate reconcile instead of waiting for the interval.

```bash

flux get kustomizations
flux get sources git
# force an immediate reconcile
flux reconcile kustomization guestbook --with-source
# tail controller logs when something looks off
flux logs --follow
```

That's the Flux story: a source plus a Kustomization, committed to Git
and reconciled by a chain of single-purpose controllers. The pipeline is
code, not clicks — which is exactly why Git-native teams like it.

## Side by Side: Choosing for Your Stack

Both tools just deployed the identical guestbook and will both keep it
matching Git. The difference is shape and ergonomics, not capability.
Use this table to map each tool to how your team actually works.

| **Dimension** | **ArgoCD** | **Flux** |
|----|----|----|
| Deployment model | Application-centric: one Application CRD per app, reconciled by the application-controller | Toolkit-centric: a chain of source-controller, kustomize-controller, and helm-controller |
| Time to first deploy | Fast: install, create one Application, click Sync (or auto-sync) | Moderate: bootstrap writes Flux into a Git repo first, then add a source plus Kustomization |
| Developer friction | Low for newcomers: GUI guides you; CLI optional | Low for Git-native teams: everything is a committed CR; no GUI to learn |
| Observability | Rich built-in web UI: live resource tree, diffs, sync history, rollback | CLI-first: flux get / flux logs / events; UI via optional add-ons (Weave GitOps, Capacitor) |
| Drift handling | Detects drift; self-heal and prune are opt-in toggles | Continuous reconcile; prune and health checks set per Kustomization |
| Multi-tenancy | AppProjects scope repos, clusters, and namespaces | Per-namespace controllers plus RBAC; tenants own their CRs |
| Best fit | Teams that want a console and visual sync/rollback out of the box | Teams that live in Git and want composable, code-only pipelines |

### The one-line rule of thumb

Reach for **ArgoCD** when you want a console out of the box — visual
sync, diffs, and rollback that an on-call engineer can drive at 2 a.m.
Reach for **Flux** when your team lives in Git and prefers composable,
code-only pipelines with no extra UI to operate. The GitOps pattern
underneath — declare in Git, pull, reconcile, correct drift — is
identical either way, so you are choosing a workflow, not a philosophy.

### Wrap-up

You've now deployed the same app with both tools and seen exactly where
they ask for your attention: ArgoCD at the Sync button, Flux at the Git
commit. Spin up a throwaway cluster, run both walkthroughs back to back,
and notice which one feels like home. That instinct — plus the table
above — is how you'll choose the right GitOps engine for your
infrastructure.

**Sources**

* ArgoCD Getting Started & Declarative Setup — argo-cd.readthedocs.io/en/stable/getting_started/ and /operator-manual/declarative-setup/
* argocd app sync command reference — argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_app_sync/
* Flux Getting Started & CLI — fluxcd.io/flux/get-started/ and fluxcd.io/flux/cmd/
* Guestbook example app — github.com/argoproj/argocd-example-apps (path: guestbook)
