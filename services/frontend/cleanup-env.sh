#/usr/bin/env sh

set -ex

helm uninstall sdp-frontend-service || true
kubectl delete secret login-cred

while [ $(kubectl get pods -l app.kubernetes.io/name=sdp-frontend --no-headers | wc -l) != 0 ]; do
    sleep 1
done
