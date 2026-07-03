# Module 1 – Control Loop

## Introduction

Kubernetes was first released in 2015 and is used widely to run container-based
workloads. Opinions about it vary, and it is often considered to be overly
complex. It doesn't have to be. I started using it in 2021 and became a proponent
once I developed a system to manage it effectively. In this video I want to
introduce you to running Kubernetes clusters using GitOps. But first, for
background, I'll describe Kubernetes itself and show a basic example.

## Kubernetes

What is Kubernetes? A Kubernetes cluster is a control plane and set of worker nodes. The control
plane stores what you want and acts on it. Nodes are the machines that actually
run your workloads. The control plane uses a data store, usually etcd, and runs an
API server. You declare what you want via the API and the cluster makes it real.
Let's take the example of a "Deployment", perhaps the most common Kubernetes
"resource kind". As an administrator, you can create a Deployment via the API
using a tool like kubectl, and assuming a valid configuration, you will see
containers running on your nodes. Let's see this in action.

[Exercise 1](../exercises/exercise-1/README.md)

## The Deployment Model

After the Deployment was applied, it took some time for the actual containers to
start. In between the Deployment and the running containers were two other
resource kinds: a ReplicaSet and a Pod. This works as a control loop driven by
controllers.

### A Control Loop
To understand the control loop, think of a thermostat.
A thermostat works as part of a system that regulates the temperature of a room
without constant manual intervention — assuming the people in the room can agree
on what the temperature should be.
It works as part of a closed control loop.
This loop includes a setpoint — the target “declared” temperature — a comparator that checks how the real
temperature differs from it, and an actuator that runs the heater or air
conditioner as needed to reconcile any difference. Feedback makes it a closed
loop: the temperature change introduced by the actuator eventually shows up at
the comparator. Declare a target, measure reality, act to match. Kubernetes
works this way.

### Controllers

Our Deployment, created via the API, starts off as just a stored idea — like a
thermostat's setpoint. Getting from that idea to running containers takes a chain
of control loops.

The kube-controller-manager contains a Deployment controller that watches
Deployments and creates a ReplicaSet. A ReplicaSet declares how many Pods should
exist — say, 3 — and tracks how many actually exist (to start, 0). The ReplicaSet
controller, also part of that same kube-controller-manager, creates Pods via the
API until the actual count matches the desired count.

So what is a Pod? A Pod is the main unit of workload running on the
cluster’s nodes. It specifies one or more containers to run. A Pod is created
"unscheduled"; the kube-scheduler then assigns it to a node.

On that node, the kubelet starts the Pod’s containers and begins periodic health
probes. The overall loop is closed when healthy, scheduled Pods satisfy the Pod
definitions, the Pods satisfy the ReplicaSet, and the ReplicaSet satisfies the
Deployment.

## Many Loops, One Pattern

As you can see, even starting a basic workload involves many closed loops, each
watching the API server and reconciling its portion of the declared state — the
setpoint. A controller decides what should exist, the scheduler decides where it
runs, and the kubelet makes it actually run. And very often controllers create
new resources using the API that trigger other controllers to run.

As an operator, you apply a Deployment and see Pods appear. Over time
the system converges to the declared state you specified. And if the running
system drifts, say from a crashing container, these same control loops will
bring it back to your desired state.

## Recap

- **Kubernetes is declarative.** You tell the API server *what* you want; the
  cluster figures out *how* to make it real.
- **A control loop reconciles desired state with reality** — like a thermostat:
  declare a target, measure reality, act to close the gap.
- **A Deployment becomes running containers through a chain of controllers:**
  Deployment → ReplicaSet → Pod, each a loop reconciling the layer below it.
- **The scheduler places Pods and the kubelet runs them,** then health-probes the
  containers to keep them running.
- **Reconciliation is continuous.** If the system drifts, the same loops pull it
  back to your declared state — the foundation GitOps builds on.
