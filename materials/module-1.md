# Module 1 – Control Loop

## Introduction

Kubernetes was first released in 2015 and is widely used to run container-based
workloads. Opinions about it vary widely. I started using it in 2021 and became
a proponent once I develpoed a system to manage it. In this video I want to
introce you to running Kubernetes clusters by storing configuration in a git
repository. But first, for background, I'll describe Kubernetes itself and its
effective use of a control loop.


### Kubernetes

What is Kubernetes? A Kubernetes cluster is a control plane and set of worker nodes. The control
plane stores what you want and acts on it. Nodes are the machines that actually
run your workloads. The control plane uses a data store, usually etcd, and runs an
API server. You declare what you want via the API and the cluster makes it real. Let's take the example of a "Deployment", perhaps the most common Kubernets "resource type". As an administrator, you can create a "Deployment" via the API using a tool like kubectl, and assuming a valid configuration, you will see containers running on your nodes. Let's see this in action.

[Exercise 1]

Deployment can be created by a call to the API. At first it information is stored, but
nothing is actually running.




In this video we'll look at how GitOps, with tools like ArgoCD and Flux, can be
used to manage Kubernetes clusters effectively. We’ll start by describing the
core of Kubernetes and how its elegant design makes GitOps a good fit. I’ll
describe how Helm, Git, and a GitOps controller such as ArgoCD or Flux manage
deployments.

We'll start with a fundamental idea: the control loop.

## Essential Kubernetes

### The Control Loop

A thermostat works as part of a control loop. This loop includes a setpoint —
the target “declared” temperature — a comparator that checks how the real
temperature differs from it, and an actuator that runs the heater or air
conditioner as needed to reconcile any difference. Feedback makes it a closed
loop: the temperature change introduced by the actuator eventually shows up at
the comparator. Declare a target, measure reality, act to match. Kubernetes
works this way.


### The Kubernetes Core: etcd and the API Server

 Our
example resource is a Deployment: a declaration of a long-running workload. But
a Deployment created via the API and sitting in etcd doesn't do anything yet.
It's just a stored idea — like a thermostat's setpoint. Getting from that idea
to running containers takes a chain of control loops.

### From Deployment to Running Container

The kube-controller-manager bundles many core controllers. Its Deployment
controller watches for new and updated Deployments and creates a ReplicaSet.

The ReplicaSet is perhaps the easiest closed loop to understand. It
declares how many Pods should exist — say, 3. It sees "want 3, have 0" and
creates Pods via the API until the actual count matches the desired count.

The ReplicaSet watches the number of Pods that exist, not whether the app inside
them is healthy. The kubelet running on a node starts containers and checks
their health regularly with probes. It restarts containers which remain
unhealthy and reports status back to the API server. The ReplicaSet controller
creates a new Pod if one is lost altogether.

So what is a Pod? A Pod is the main unit of workload running on the
cluster’s nodes. It specifies one or more containers set up to run with a
specific command, mounted volumes, and environment variables. Pods are created
“unscheduled” by the controller. The kube-scheduler then assigns unscheduled
Pods to a node.

Only then does the kubelet, the primary actuator on each node, start the
Pod’s containers and begin periodic health probes. The overall loop is closed
when healthy, scheduled Pods satisfy the Pod definitions, the Pods satisfy the
ReplicaSet, and the ReplicaSet satisfies the Deployment.

### Many Loops, One Pattern

As you can see, even starting a basic workload involves many closed loops, each
watching the API server and reconciling its portion of the declared state — the
setpoint. A controller decides what should exist, the scheduler decides where it
runs, and the kubelet makes it actually run. And very often controllers create
new resources using the API that trigger other controllers to run.

As an operator, you apply a Deployment and see Pods appear. Over time
the system converges to the declared state you specified. And if the running
system drifts, say from a crashing container, these same control loops will
bring it back to your desired state.
