#!/bin/bash
PROJECTDIR=$(git rev-parse --show-toplevel)
cd $PROJECTDIR/manifests || exit
kubectl delete -f antaeus-deployment.yaml
kubectl delete -f payments-deployment.yaml
kubectl delete -f antaeus-service.yaml
kubectl delete -f payments-service.yaml
kubectl delete -f common-secrets.yaml
kubectl delete -f antaeus-configmap.yaml
kubectl delete -f payments-network-policy.yaml
kubectl delete -f payments-namespace.yaml
