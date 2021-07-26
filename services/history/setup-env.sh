#/usr/bin/env sh

set -ex

wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/55/packages/generic/history-server-helm-chart/0.1.0/history-server-0.1.0.tgz
tar -zxf history-server-0.1.0.tgz
helm install history-server --set eventLog.alluxioService=${ALLUXIO_SVC} --set eventLog.dir=${SPARK_EVENTLOG_DIR} history-server/ --wait

while [ $(kubectl get pod -l app.kubernetes.io/name=history-server -o jsonpath="{.items[0].status.phase}") != 'Running'  ]; do
  sleep 1
done

kubectl describe pods
kubectl get pods