#/usr/bin/env sh

set -ex

helm uninstall metadata-service || true
kubectl delete secret metadata-login-cred
