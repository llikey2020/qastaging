#/usr/bin/env sh

set -ex

kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -RU /${SPARK_WAREHOUSE} || true
kubectl exec alluxio-master-0 -c alluxio-master -- alluxio fs rm -RU /${SPARK_DEPENDENCY_DIR} || true
helm uninstall alluxio alluxio-charts/alluxio || true
kubectl delete pod ${SPARK_DRIVER_POD_NAME} --wait=true --ignore-not-found=true
kubectl delete service/${MYSQL_SVC_NAME} deployment/${MYSQL_SVC_NAME} || true
helm uninstall zeppelin-service || true
helm uninstall hive-metastore-service || true
helm uninstall metadata-service || true
helm uninstall history-server || true
helm uninstall sdp-frontend-service || true