#!/bin/bash
PROJECTDIR=$(git rev-parse --show-toplevel)
cd "$PROJECTDIR"/manifests || exit
kubectl apply --dry-run=client -f payments-namespace.yaml
kubectl apply --dry-run=client -f payments-network-policy.yaml
kubectl apply --dry-run=client -f common-secrets.yaml
kubectl apply --dry-run=client -f antaeus-configmap.yaml
kubectl apply --dry-run=client -f antaeus-deployment.yaml
kubectl apply --dry-run=client -f antaeus-service.yaml
kubectl apply --dry-run=client -f payments-deployment.yaml
kubectl apply --dry-run=client -f payments-service.yaml
