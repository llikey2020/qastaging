#/usr/bin/env sh

set -ex

kubectl delete secret history-login-cred
helm uninstall history-server || true
