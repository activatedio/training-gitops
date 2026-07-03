# Exercise 1 — The Control Loop

A hands-on walk through a simple Deployment and how it propagates through to a
ReplicaSet and Pods.

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

Open a **second terminal** and run the following command to see the events
propagate in real time.

```bash
kubectl get events -n loop-demo --watch
```

## Apply the deployment

Apply the simple manifest `manifest.yaml` to create a Namespace, Deployment,
ReplicaSet, and Pods:

```bash
kubectl apply -f manifest.yaml
```

The objects are now created. Watch the rollout converge:

```bash
kubectl rollout status deployment/web -n loop-demo --timeout=90s
```

## See what the controllers built

The Deployment controller created a ReplicaSet, which created Pods, which the
scheduler placed on nodes:

```bash
kubectl get deployment,replicaset,pods -n loop-demo -o wide
```

Note the **owner chain**: Deployment → ReplicaSet → Pod. Each is created by a
controller as the cluster converges to the state you specified.
