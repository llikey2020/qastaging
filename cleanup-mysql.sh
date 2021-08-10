#/usr/bin/env sh

set -ex

kubectl delete pod ${SPARK_DRIVER_POD_NAME} --wait=true --ignore-not-found=true
kubectl delete service/${MYSQL_SVC_NAME} deployment/${MYSQL_SVC_NAME} || true]