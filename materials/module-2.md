# Module 2 – Resources and Helm Charts

## Resources

In Module 1 we watched a single Deployment produce ReplicaSets and Pods.
Those are just three of roughly 60 built-in resource kinds in a typical
cluster. Common ones include: ConfigMaps for runtime configuration,
Secrets for sensitive values, Services to expose Pod ports, Namespaces
for logical organization, and StatefulSets for workloads that need
stable storage and a stable network identity. Every one of them follows
the same rule: you declare it, and a controller works to make it real.

## The problem with raw manifests

You can apply any resource directly. In practice you do it with a tool —
kubectl apply -f manifest.yaml reads the resources defined in a manifest
file and sends them to the API server. The command is usually
idempotent: run it again and you get the same result, not a duplicate.
For a few files this is simple and reliable. But a real application is
dozens of interdependent resources across multiple environments, and
hand-managing those raw manifests — keeping dev, staging, and prod in
sync — becomes unmanageable fast. We need a way to *package* an
application.

## Helm: packaging the declaration

That's what Helm does. Born as a hackathon project in 2015, it's now the
de-facto way to package Kubernetes applications. A Helm chart bundles an
application's resources as templates plus a set of default values the
installer can override — so one chart deploys to many environments just
by changing values. helm install renders those templates and applies the
resulting YAML. You *could* render a chart to plain manifests and apply
them yourself, but then upgrades and removals fall back on you to diff
by hand. Helm tracks what it installed, so it can upgrade and uninstall
cleanly. Helm answers *what to deploy* — but it still waits for a human
to run the command.

## GitOps: Git as the setpoint

This is where the control loop returns. This is the idea behind
*GitOps*. A GitOps controller runs inside the cluster, watches a Git
repository, and continuously reconciles the live cluster to match it —
Git becomes the declared state, the setpoint for the whole cluster. You
commit a change; the controller detects the difference between Git and
the live cluster and applies it. If someone changes the cluster by hand,
the controller sees the drift and can correct it — exactly the
self-healing behavior we saw with ReplicaSets, now lifted to the level
of the entire application. Four ideas define the pattern: the desired
state is declared in Git, the controller pulls that state rather than
waiting for an external system to push it, reconciliation runs
continuously in a closed loop, and drift is detected and corrected
automatically. Plain manifests, Kustomize overlays, and Helm charts can
all serve as the declared state. GitOps turns “declare your state, let a
loop converge to it” into your whole deployment workflow. Two graduated
CNCF projects dominate this space — ArgoCD and Flux. They reach the same
outcome by different routes.

ArgoCD: the application-centric approach

ArgoCD is the application-centric take on this pattern. Its central
object is the Application: you tell ArgoCD which Git repository and path
hold your manifests and which cluster and namespace they target, and it
reconciles that Application to match. ArgoCD ships with a web UI that
draws the live resource tree, shows the diff between Git and the
cluster, and lets operators sync or roll back with a click — which is
why teams that want visibility tend to reach for it first. It
understands plain manifests, Kustomize, and Helm: point it at a chart,
and it manages installs, upgrades, and removals as Git changes. Sync can
be manual or fully automated, with optional self-healing and pruning of
resources you delete from Git.

Flux: the toolkit approach

Flux reaches the same outcome through a toolkit of small, single-purpose
controllers — the GitOps Toolkit. A source-controller fetches the
declared state from a GitRepository, Helm repository, or OCI artifact
and makes it available to the others. A kustomize-controller applies
plain manifests and Kustomize overlays from a Kustomization resource,
while a helm-controller manages chart releases from a HelmRelease. A
notification-controller reports results and can receive webhooks to
trigger an immediate sync. There is no built-in UI by default; Flux is
operator- and CLI-first, driven by the *flux* command and Kubernetes
custom resources, which makes it composable and easy to extend. The
reconciliation philosophy is the same as ArgoCD’s: pull from Git,
converge continuously, and correct drift automatically.

Same pattern, different shape

Both tools produce the same end result: the cluster matches the Git
commit you point them at, and both keep it there. They differ mainly in
shape. ArgoCD is application-centric and UI-first, with a single
Application object and a console operators reach for at 2 a.m. Flux is
operator-centric and CLI-first, a set of composable controllers wired
together through custom resources. Pick the one whose default workflow
matches how your team works; the GitOps pattern underneath is identical.
In the next module we will put each tool to work with concrete examples.
