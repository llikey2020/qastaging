#/usr/bin/env sh

set -ex

kubectl delete secret history-login-cred
helm uninstall history-server || true

# wait for service pods to be deleted
while [ $(kubectl get pods -l app=history-server --no-headers | wc -l) != 0 ]; do
    sleep 1
done