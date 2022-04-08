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
echo " Waiting for antaeus to be ready..."
PAYMENT_POD=$(kubectl -n payments get pods --field-selector status.phase=Running -l app=payments -o jsonpath='{.items[*].metadata.name}')
kubectl wait --for=condition=Ready --timeout=60s -n payments pod $PAYMENT_POD
ANTAEUS_POD=$(kubectl -n payments get pods --field-selector status.phase=Running -l app=antaeus -o jsonpath='{.items[*].metadata.name}')
kubectl wait --for=condition=Ready --timeout=60s -n payments pod $ANTAEUS_POD
