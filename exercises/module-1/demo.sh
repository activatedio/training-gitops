#!/usr/bin/env bash
set -euo pipefail

CLUSTER=gitops-demo
NS=loop-demo

pause() { echo; read -rp "  ↵ press enter to continue..."; echo; }

echo "==> 1. Create a fresh 3-node cluster (1 control-plane, 2 workers)"
kind create cluster --config kind-config.yaml
kubectl cluster-info --context "kind-${CLUSTER}"
kubectl get nodes -o wide
pause

echo "==> 2. Create a namespace to keep the demo isolated"
kubectl create namespace "${NS}"
kubectl config set-context --current --namespace="${NS}"
pause

echo "==> 3. In a SECOND terminal, start watching events live now:"
echo "     kubectl get events -n ${NS} --watch"
echo "    (or sorted after the fact: kubectl get events -n ${NS} --sort-by=.metadata.creationTimestamp)"
pause

echo "==> 4. Declare the Deployment — the 'setpoint'"
kubectl create deployment web --image=nginx:1.27 --replicas=3
echo
echo "    The object now sits in etcd. Watch the controllers close the loop:"
pause

echo "==> 5. Watch the rollout converge to the declared state"
kubectl rollout status deployment/web --watch --timeout=90s
pause

echo "==> 6. See the hierarchy the controllers built: Deployment -> ReplicaSet -> Pods"
kubectl get deployment,replicaset,pods -o wide
echo
echo "    Note the OWNER chain and which WORKER NODE the scheduler placed each Pod on."
pause

echo "==> 7. Inspect the events in time order (scheduling + kubelet activity)"
kubectl get events --sort-by=.metadata.creationTimestamp
pause

echo "==> 8. Break a loop on purpose: delete one Pod and watch the ReplicaSet replace it"
VICTIM=$(kubectl get pods -l app=web -o jsonpath='{.items[0].metadata.name}')
echo "    Deleting Pod: ${VICTIM}"
kubectl delete pod "${VICTIM}"
echo
echo "    The ReplicaSet sees 'want 3, have 2' and creates a replacement:"
kubectl get pods -l app=web -o wide --watch &
WATCH_PID=$!
sleep 12
kill "${WATCH_PID}" 2>/dev/null || true
pause

echo "==> 9. Trace the ownership explicitly"
RS=$(kubectl get rs -l app=web -o jsonpath='{.items[0].metadata.name}')
echo "    ReplicaSet ${RS} is owned by:"
kubectl get rs "${RS}" -o jsonpath='{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}{"\n"}'
POD=$(kubectl get pods -l app=web -o jsonpath='{.items[0].metadata.name}')
echo "    Pod ${POD} is owned by:"
kubectl get pod "${POD}" -o jsonpath='{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}{"\n"}'
pause

echo "==> 10. Clean up"
read -rp "  Delete the cluster? [y/N] " ans
[[ "${ans:-N}" =~ ^[Yy]$ ]] && kind delete cluster --name "${CLUSTER}"
echo "Done."
