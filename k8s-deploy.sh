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

export ANTAEUS_POD=$(kubectl -n payments get pods -l app=antaeus -o jsonpath='{.items[*].metadata.name}')

echo " Waiting up to 60s for antaeus to be ready..."
kubectl wait -n payments --for condition=ready pod --all
kubectl logs -n payments $ANTAEUS_POD
