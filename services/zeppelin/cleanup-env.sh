#/usr/bin/env sh

set -ex

helm uninstall zeppelin-service || true
kubectl delete secret zeppelin-login-cred
