# Module 2 – Resources, Helm Charts, ArgoCD

## Resources

In Module 1 we watched a single Deployment produce ReplicaSets and Pods. Those
are just three of roughly 60 built-in resource kinds in a typical cluster.
Common ones include: ConfigMaps for runtime configuration, Secrets for sensitive
values, Services to expose Pod ports, Namespaces for logical organization, and
StatefulSets for workloads that need stable storage and a stable network
identity.

## Raw Manifests

You can apply any resource directly with kubectl, like we did. The command is
usually idempotent: run it again and you get the same result, not a duplicate. At
a small scale this is simple and reliable. As you scale up, you will want a better
way to package related resources.

## Helm

That's what Helm does. Started as a hackathon project in 2015, it provides a
useful way to package Kubernetes applications. A Helm chart bundles an
application's resources as templates plus a set of default values the installer
can override. Helm helps define *what* to deploy. A number of tools can expand
and apply Helm charts onto a cluster, including the *helm* utility itself. Some of
these tools combine Helm charts with "GitOps".

## GitOps

*GitOps* introduces a powerful control loop to handle *how to deploy*. A
controller with access to a Git repository runs inside the cluster, watches the
repository, and reconciles the live cluster to match it. Git becomes the
declared state. You commit a change, and the controller either reconciles the
difference between Git and the live cluster automatically or displays the
difference so you can decide whether to apply it.

GitOps rests on four ideas. The desired state is declared in Git, the controller
pulls that state rather than waiting for an external system to push it,
reconciliation runs continuously in a closed loop, and drift is detected and
corrected.

Plain manifests, Kustomize overlays, and Helm charts all work great with this
approach. To see this in action we can use ArgoCD.

## ArgoCD

Before we start working with ArgoCD, I want to share my preferred approach
to using it. You are welcome to follow my approach or use it as a starting point
for your own.

Here are some of my preferences.

* I prefer writing my own manifests rather than using scaffolding tools that
  generate manifests from commands.
* I rarely use the `argocd` CLI, preferring the UI to view the state of the
  system and take action.
* I avoid Kustomize, as I find it clunky to use and rarely needed.
* I structure my installs into three buckets:
  * ops for internal tools
  * non-prod for workloads not in production, like test environments
  * and prod for, well, production workloads
* Where I see repeated installs across many environments, I use an ApplicationSet.
* I layer my installs:
  * __cluster-resources__ – for resources specific to a cluster that don’t fit
    neatly in an application or application set. Examples include storage
    classes and my ArgoCD ingress.
  * __roots__ – applications pointed at a git path that contains other
    applications or application sets. I use them for major groupings across
    environments and clusters. There are typically two kinds of roots:
    * __cluster-addons__ – typically created once, these contain common
      supporting utilities and applications like sealed secrets, external-dns,
      cert-manager, and Prometheus.
    * __app roots__ – I follow this same pattern to install app-specific projects
      and roots for my workloads across environments.

Let's start to apply this pattern. I won't get into a specific environment
strategy. We will set up a cluster-addons root, cluster-resources, and a single
"example" root into which we will install a single application.

[Exercise 2](../exercises/exercise-2/README.md)
