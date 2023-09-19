#!/usr/bin/env sh

GREENPOD=$(kubectl get pod -n blue-green --selector 'env=green' --output=jsonpath={.items..metadata.name} | cut -d ' ' -f1)
kubectl expose pod $GREENPOD -n blue-green --type NodePort --target-port 80

GREENPORT=$(kubectl get svc $GREENPOD -n blue-green | tail -1 | awk '{print $5}' | awk -F ':' '{print $2}' | awk -F '/' '{print $1}')
sleep 1s

open http://localhost:$GREENPORT