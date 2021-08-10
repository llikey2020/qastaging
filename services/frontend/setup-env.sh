#/usr/bin/env sh

set -ex

FRONTEND_DOCKER_LOGIN_SECRET=login-cred
kubectl create secret docker-registry ${FRONTEND_DOCKER_LOGIN_SECRET} --namespace=${KUBE_NAMESPACE} --docker-server=${CI_REGISTRY} --docker-username=${CI_REGISTRY_USER} --docker-password=${CI_REGISTRY_PASSWORD}

wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/46/packages/generic/sdp-frontend-helm-chart/0.0.2/sdp-frontend-0.0.2.tgz
tar xf sdp-frontend-0.0.2.tgz

helm upgrade --install \
  --set backendServices[0].name="METASTORE" \
  --set backendServices[0].value="hive-metastore-service" \
  --set backendServices[1].name="SPARK_HISTORY_SERVER" \
  --set backendServices[1].value="history-server" \
  --set backendServices[2].name="ZEPPELIN" \
  --set backendServices[2].value="zeppelin-server" \
  sdp-frontend-service sdp-frontend

while [ $(kubectl get pod -l app.kubernetes.io/name=sdp-frontend -o jsonpath="{.items[0].status.phase}") != 'Running'  ]; do
  sleep 1
done
