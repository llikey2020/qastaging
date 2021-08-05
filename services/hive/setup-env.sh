#/usr/bin/env sh

set -ex

HIVE_DOCKER_LOGIN_SECRET=hive-login-cred
kubectl create secret docker-registry ${HIVE_DOCKER_LOGIN_SECRET} --namespace=${KUBE_NAMESPACE} --docker-server=${CI_REGISTRY} --docker-username=${CI_REGISTRY_USER} --docker-password=${CI_REGISTRY_PASSWORD}

wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/44/packages/generic/helm-chart/0.1.0/hive-metastore-0.1.0.tgz
tar xf hive-metastore-0.1.0.tgz

helm upgrade --install \
  --set image.pullSecrets=${HIVE_DOCKER_LOGIN_SECRET} \
  --set image.registry=${CI_REGISTRY} \
  --set image.repository=sequoiadp/hive-metastore-helmchart \
  --set image.tag=latest \
  --set image.pullPolicy=Always \
  hive-metastore-service hive-metastore

while [ $(kubectl get pod -l app.kubernetes.io/name=hive-metastore -o jsonpath="{.items[0].status.phase}") != 'Running'  ]; do
  sleep 1
done