#/usr/bin/env sh

set -ex

kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -RU /${SPARK_WAREHOUSE} || true
kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -RU /${SPARK_DEPENDENCY_DIR} || true
helm uninstall alluxio alluxio-charts/alluxio || true

# wait for service pods to be deleted
while [ $(kubectl get pods -l app=alluxio --no-headers | wc -l) != 0 ]; do
    sleep 1
done