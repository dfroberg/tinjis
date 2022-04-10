#!/bin/bash
PROJECTDIR=$(git rev-parse --show-toplevel)
cd $PROJECTDIR/manifests
kubectl apply -f payments-namespace.yaml
kubectl apply -f payments-network-policy.yaml
kubectl apply -f common-secrets.yaml
kubectl apply -f antaeus-configmap.yaml
kubectl apply -f antaeus-deployment.yaml
kubectl apply -f antaeus-service.yaml
kubectl apply -f payments-deployment.yaml
kubectl apply -f payments-service.yaml

echo " Waiting up to 240s for antaeus to be ready..."
kubectl wait -n payments --timeout=240s --for=condition=available deployment --all
