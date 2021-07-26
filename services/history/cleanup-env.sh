#/usr/bin/env sh

set -ex

helm uninstall history-server || true
