#/usr/bin/env sh

set -ex

helm uninstall hive-metastore-service || true
kubectl delete secret hive-login-cred

# wait for service pods to be deleted
while [ $(kubectl get pods -l app.kubernetes.io/name=hive-metastore --no-headers | wc -l) != 0 ]; do
    sleep 1
done