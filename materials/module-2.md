# Module 2 – Resources and Helm Charts

## Resources

In Module 1 we watched a single Deployment produce ReplicaSets and Pods. Those
are just three of roughly 60 built-in resource kinds in a typical cluster.
Common ones include: ConfigMaps for runtime configuration, Secrets for sensitive
values, Services to expose Pod ports, Namespaces for logical organization, and
StatefulSets for workloads that need stable storage and a stable network
identity. Every one of them follows the same rule: you declare it, and a
controller works to make it real.

## The problem with raw manifests

You can apply any resource directly. In practice you do it with a tool.
`kubectl apply -f manifest.yaml` reads the resources defined in a manifest file
and sends them to the API server. The command is usually idempotent. Run it
again and you get the same result, not a duplicate. For a few files this is
simple and reliable. But a real application is dozens of interdependent
resources across multiple environments, and hand-managing those raw manifests —
keeping dev, staging, and prod in sync — becomes unmanageable fast. We need a
way to *package* an application.

## Helm: packaging the declaration

That's what Helm does. Started as a hackathon project in 2015, it's now the
de-facto way to package Kubernetes applications. A Helm chart bundles an
application's resources as templates plus a set of default values the installer
can override — so one chart deploys to many environments just by changing
values. `helm install` renders those templates and applies the resulting YAML. You
*could* render a chart to plain manifests and apply them yourself, but then
upgrades and removals fall back on you to diff by hand. Helm tracks what it
installed, so it can upgrade and uninstall cleanly. Helm answers *what to
deploy* — but it still waits for a human to run the command.

## GitOps: Git as the setpoint

*GitOps* introduces a useful control loop to handle *how to deploy*. A
controller with access to a Git repository runs inside the cluster, watches the
repository, and reconciles the live cluster to match it. Git becomes the
declared state. You commit a change, the controller detects the difference
between Git and the live cluster and either applies it automatically, or allows
you to manually apply it after a review. If someone changes the cluster by hand,
the controller sees the drift and can correct it. GitOps rests on four ideas:
the desired state is declared in Git, the controller pulls that state rather
than waiting for an external system to push it, reconciliation runs continuously
in a closed loop, and drift is detected and corrected. Plain manifests,
Kustomize overlays, and Helm charts can all be used to define the desired state
of the cluster. GitOps turns “declare your state, let a loop converge to it”
into your whole deployment workflow. ArgoCD and Flux are two widely used tools
that achieve this.

### ArgoCD: the application-centric approach

ArgoCD takes an application-centric approach. Using an Application resource, you
define the Git repository and path for your manifests and the target cluster
and namespace. ArgoCD reconciles the cluster resources to match. ArgoCD ships
with a very useful web UI that displays the live resource tree, shows the diff
between Git and the cluster, and lets operators sync. It can be used with plain
manifests, Kustomize, and Helm charts. By connecting other Kubernetes clusters to
your ArgoCD instance, you can manage multiple clusters from a single system.

### Flux: the toolkit approach

Flux takes a more lightweight, modular approach and does not ship with a web UI
(though one can be added). It is built from a handful of single-purpose
controllers. A source-controller fetches the declared state from a
GitRepository, Helm repository, or OCI artifact. A kustomize-controller applies
plain manifests and Kustomize overlays, while a helm-controller reconciles
HelmRelease resources, installing and upgrading the actual Helm releases to
match. A notification-controller reports
results and can receive webhooks to trigger an immediate sync. Flux is operator-
and CLI-first, driven by the *flux* command and Kubernetes custom resources. The
reconciliation philosophy is the same as ArgoCD’s: pull from Git, converge
continuously, and correct drift automatically.

In the next module we will put each tool to work with concrete examples.
