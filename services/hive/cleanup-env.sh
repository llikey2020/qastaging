#/usr/bin/env sh

set -ex

helm uninstall hive-metastore-service || true
kubectl delete secret hive-login-cred
