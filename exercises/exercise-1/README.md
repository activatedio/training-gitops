# Exercise 1 — The Control Loop

A hands-on walk through showing a simple Deployment and how it propgates through to a ReplicaSet and Pods.

## Prerequisites

- [`kind`](https://kind.sigs.k8s.io/) and `kubectl` installed
- Docker (or another container runtime kind supports) running

## Create a fresh cluster

A default single-node cluster is all we need here:

```bash
kind create cluster
```

Confirm it's up:

```bash
kubectl get nodes -o wide
```

## Watch events live

Open a **second terminal** and run the following command to see the events propogate in real time.

```bash
kubectl get events -n loop-demo --watch
```

## Apply and deployment

Apply the simple manifest and `manifest.yaml` to see a Deployment, ReplicaSet, and Pods created:

```bash
kubectl apply -f manifest.yaml
```

The objects now created and you can watch the rollout converge:

## See what the controllers built

The Deployment controller created a ReplicaSet, which created Pods, which the
scheduler placed on nodes:

```bash
kubectl get deployment,replicaset,pods -n loop-demo -o wide
```

Note the **owner chain**: Deployment → ReplicaSet → Pod. These are each deployed by controllers as the state is converged to what you have specified.
