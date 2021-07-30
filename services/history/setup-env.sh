#/usr/bin/env sh

set -ex

HISTORY_DOCKER_LOGIN_SECRET=history-login-cred
kubectl create secret docker-registry ${HISTORY_DOCKER_LOGIN_SECRET} --namespace=${KUBE_NAMESPACE} --docker-server=${CI_REGISTRY} --docker-username=${CI_REGISTRY_USER} --docker-password=${CI_REGISTRY_PASSWORD}

wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/55/packages/generic/history-server-helm-chart/0.1.0/history-server-0.1.0.tgz
tar -zxf history-server-0.1.0.tgz
helm upgrade --install \
  --set eventLog.alluxioService=${ALLUXIO_SVC} \
  --set eventLog.dir=${SPARK_EVENTLOG_DIR} \
  --set image.pullPolicy=Always \
  --set imagePullSecrets="[{\"name\": \"${HISTORY_DOCKER_LOGIN_SECRET}\"}]" \
  history-server history-server/
  

while [ $(kubectl get pod -l app=history-server -o jsonpath="{.items[0].status.phase}") != 'Running'  ]; do
  sleep 1
done
