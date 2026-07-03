# Exercise 1 — The Control Loop

A hands-on walk through Kubernetes' control loop. Run the commands yourself,
one at a time, and watch the controllers converge a declared Deployment into
running Pods — then break it and watch them reconcile it back.

This is command-driven: the README is the guide, and you run each step.

## Prerequisites

- [`kind`](https://kind.sigs.k8s.io/) and `kubectl` installed
- Docker (or another container runtime kind supports) running

## 1. Create a fresh cluster

A default single-node cluster is all we need here:

```bash
kind create cluster
```

Confirm it's up:

```bash
kubectl cluster-info --context kind-kind
kubectl get nodes -o wide
```

## 2. Watch events live (second terminal)

Open a **second terminal** and leave this running for the rest of the exercise.
It's your window into the control loops closing in real time:

```bash
kubectl get events -n loop-demo --watch
```

## 3. Declare the desired state

Apply the manifest — a `loop-demo` Namespace and a `web` Deployment
(nginx, 3 replicas). This is the "setpoint": you declare what you want, and
the cluster's controllers make it real.

```bash
kubectl apply -f manifest.yaml
```

The objects now sit in etcd. Watch the rollout converge:

```bash
kubectl rollout status deployment/web -n loop-demo --timeout=90s
```

## 4. See what the controllers built

The Deployment controller created a ReplicaSet, which created Pods, which the
scheduler placed on nodes:

```bash
kubectl get deployment,replicaset,pods -n loop-demo -o wide
```

Note the **owner chain**: Deployment → ReplicaSet → Pod. Each layer is a
controller reconciling the layer below it toward your declared state.

## On your own

Now try breaking a loop and watching it reconcile: delete one of the Pods
(`kubectl delete pod -n loop-demo <pod-name>`) and watch the ReplicaSet notice
"want 3, have 2" and spin up a replacement — the same closed loop, self-healing
back to your declared state. Keep the event watch from step 2 open to see it
happen live.

When you're done, clean up with `kubectl delete -f manifest.yaml` or tear down
the whole cluster with `kind delete cluster`.
