#/usr/bin/env sh

set -ex

helm uninstall zeppelin-service || true
kubectl delete secret zeppelin-login-cred

# wait for service pods to be deleted
while [ $(kubectl get pods -l app.kubernetes.io/name=zeppelin-server --no-headers | wc -l) != 0 ]; do
    sleep 1
done