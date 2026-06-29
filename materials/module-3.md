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

The guestbook is a small web app and the canonical GitOps demo. The Argo
project publishes it at github.com/argoproj/argocd-example-apps in a
folder named guestbook, as plain Kubernetes manifests — a Deployment and
a Service. Starting both tools from the same manifests lets us compare
them fairly. For ArgoCD we'll copy those manifests into our own Git repo
(so we can change them and watch the diff); for Flux we'll point straight
at the upstream repo. Either way the workload is identical — only the
machinery that delivers it differs.

Remember the shape difference from Module 2. ArgoCD wraps the whole app
in a single object — an Application — and gives you a console to sync
it. Flux assembles the same outcome from a chain of small controllers,
each reading a custom resource you commit to Git. Watch for that
contrast as we go.

## Walkthrough 1 — ArgoCD: bootstrap once, then drive everything from Git

You *could* install ArgoCD by piping the upstream manifest into the
cluster and poking it with the `argocd` CLI — that's how most quickstarts
do it. But it quietly undercuts the whole point. If the tool that
reconciles Git is itself installed and changed by hand, its own config
drifts and nobody can review it. So we'll be GitOps from the very first
step. We start from a small **bootstrap template** —
`github.com/activatedio/argocd-bootstrap` — that installs an ArgoCD which
*manages itself from Git*. After that, every change — to ArgoCD or to our
apps — is a commit you review in the console, never an imperative command.

The template is plain Kustomize + `kubectl`, no extra CLI to learn. Once
bootstrapped it wires three things together: an `argo-cd` Application that
syncs ArgoCD's own install (bump a version, commit, it upgrades itself), a
`root` Application that manages your `projects/`, and a `default`
ApplicationSet that turns every directory under `apps/*` into an
Application automatically. That `apps/*` convention is how we'll ship the
guestbook — no app to register by hand.

### Step 1: Clone the template into a repo you control

Bootstrap reads its manifests back from Git, so they have to live in a
repo you own.

```bash
git clone https://github.com/activatedio/argocd-bootstrap
cd argocd-bootstrap
git remote set-url origin https://github.com/you/your-gitops-repo
git push -u origin main
```

### Step 2: Install ArgoCD with one make target

`make install` bakes your repo URL and the ArgoCD version into the
manifests, creates the namespace and a repo-access secret from your token,
server-side-applies the ArgoCD install, waits for it, then applies the
self-managing Applications. You need a Git token with read access to the
repo.

```bash
make install \
  GIT_REPO=https://github.com/you/your-gitops-repo \
  GIT_TOKEN=ghp_your_token \
  ARGOCD_VERSION=v3.2.12

# publish the rendered manifests so ArgoCD reads the same values back
git commit -am "bootstrap argo-cd" && git push
```

That push is the important part: the cluster now reconciles *this repo*.
From here, changing ArgoCD — or anything it manages — means committing to
Git, not running imperative commands.

### Step 3: Open the UI

```bash
make password        # prints the initial admin password (user: admin)
make port-forward    # forwards the console to https://localhost:8080
```

Log in and the control plane is already describing itself: the `argo-cd`,
`root`, and `default` objects show up Synced and Healthy. This is the
graphical control plane — everything below is Git plus a few clicks, and
you never touch the `argocd` CLI.

### Step 4: Start with sync by hand

The template's `default` ApplicationSet ships with automated sync turned
*on*. We'll switch it off first, so we can drive the first syncs ourselves
and review every diff before it lands — the habit worth building before
you trust a new app. Open `projects/default.yaml` and remove the
`automated` block from the ApplicationSet's template:

```diff
       syncPolicy:
-        automated:
-          prune: true
-          selfHeal: true
         syncOptions:
           - ServerSideApply=true
           - CreateNamespace=true
```

```bash
git commit -am "apps: manual sync to start" && git push
```

The `root` Application picks up the change, and from now on the `default`
ApplicationSet creates each app **OutOfSync**, waiting for you to sync it.

### Step 5: Add the guestbook under apps/

Deploy the guestbook the GitOps way: drop its manifests into
`apps/guestbook/` and let the ApplicationSet discover them. The guestbook
is just a Deployment and a Service — copy the two upstream manifests in:

```bash
mkdir -p apps/guestbook
# apps/guestbook/guestbook-ui-deployment.yaml  (image gcr.io/google-samples/gb-frontend:v5)
# apps/guestbook/guestbook-ui-svc.yaml
git add apps/guestbook
git commit -m "add guestbook" && git push
```

On its next git poll the ApplicationSet creates a `guestbook` Application.
In the UI it's **OutOfSync**: ArgoCD knows the desired state from Git but
hasn't applied it. Open the app, watch the resource tree light up, and
press **Sync**. The guestbook converges to Healthy.

### Step 6: Change the guestbook and apply it from the diff

Here's the everyday GitOps loop — and the reason manual sync is worth
seeing first. Bump the container image in
`apps/guestbook/guestbook-ui-deployment.yaml`:

```diff
-        - image: gcr.io/google-samples/gb-frontend:v5
+        - image: gcr.io/google-samples/gb-frontend:v4
```

```bash
git commit -am "guestbook: pin gb-frontend v4" && git push
```

Within a minute ArgoCD polls the repo and marks guestbook **OutOfSync**
again. This time, before syncing, open the **App Diff** panel on the
application in the UI. You'll see exactly the one-line image change you
committed — desired (Git) on one side, live (cluster) on the other. That
review step — *see precisely what will change before it changes* — is the
heart of GitOps, and it's why teams sync by hand until they trust a given
app. Once you're happy, press **Sync**, and ArgoCD rolls the Deployment to
the new image.

### Step 7: Turn on auto-sync

Once you trust the loop, hand it the keys. Put the `automated` block back
on the ApplicationSet — now every app under `apps/*` syncs itself,
self-heals manual drift, and prunes whatever you delete from Git:

```diff
       syncPolicy:
+        automated:
+          prune: true
+          selfHeal: true
         syncOptions:
           - ServerSideApply=true
           - CreateNamespace=true
```

```bash
git commit -am "apps: enable automated sync" && git push
```

Now the diff-then-click step disappears: commit a change and ArgoCD
applies it on its own. The manual phase you just practiced is the on-ramp;
auto-sync is where apps live once you trust them.

That's the ArgoCD story, GitOps-first: a template that installs an ArgoCD
which manages itself, a guestbook shipped by dropping files under `apps/`,
a diff you review before each manual sync, and an automated policy you flip
on with a single commit. You never had to drive the tool imperatively —
Git and the console did all the work.

> **Coming up.** We kept this walkthrough to a single app on a local
> cluster, but the bootstrap template is the foundation for a lot more.
> In future modules we'll build on it to: carve workloads into **multiple
> AppProjects** for per-team RBAC and source/destination scoping; stand up
> **root Applications** (the app-of-apps pattern) to fan out across many
> Applications and clusters; **install an ingress controller** through the
> same `apps/*` mechanism; and integrate ArgoCD with a cloud account —
> putting the ArgoCD server **behind a load balancer** for easy team
> access, and wiring up **IAM and GKE Workload Identity** so ArgoCD can
> form automated, keyless connections to managed cloud clusters.

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
| Time to first deploy | Fast once bootstrapped: a template installs a self-managing ArgoCD, then drop apps under `apps/*` and Sync (or auto-sync) | Moderate: bootstrap writes Flux into a Git repo first, then add a source plus Kustomization |
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

* argocd-bootstrap template — github.com/activatedio/argocd-bootstrap
* ArgoCD Declarative Setup, ApplicationSet & app-of-apps — argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/, /operator-manual/applicationset/, and /operator-manual/cluster-bootstrapping/
* Flux Getting Started & CLI — fluxcd.io/flux/get-started/ and fluxcd.io/flux/cmd/
* Guestbook example app — github.com/argoproj/argocd-example-apps (path: guestbook)
