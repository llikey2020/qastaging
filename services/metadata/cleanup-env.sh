#/usr/bin/env sh

set -ex

helm uninstall metadata-service || true
kubectl delete secret metadata-login-cred

# wait for service pods to be deleted
while [ $(kubectl get pods -l app=metadata-microservice --no-headers | wc -l) != 0 ]; do
    sleep 1
done