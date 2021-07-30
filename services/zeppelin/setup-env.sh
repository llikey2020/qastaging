#/usr/bin/env sh

set -ex

ZEPPELIN_DOCKER_LOGIN_SECRET=zeppelin-login-cred
kubectl create secret docker-registry ${ZEPPELIN_DOCKER_LOGIN_SECRET} --namespace=${KUBE_NAMESPACE} --docker-server=${CI_REGISTRY} --docker-username=${CI_REGISTRY_USER} --docker-password=${CI_REGISTRY_PASSWORD}

wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/41/packages/generic/zeppelin-helm-chart/0.1.0/zeppelin-0.1.0.tgz
tar xf zeppelin-0.1.0.tgz

helm upgrade --install \
  --set imagePullSecrets="[{\"name\": \"${ZEPPELIN_DOCKER_LOGIN_SECRET}\"}]" \
  --set image.repository=${CI_REGISTRY}/sequoiadp/zeppelin:latest \
  --set image.pullPolicy=Always \
  --set spark.repository=${CI_REGISTRY}/sequoiadp/spark:latest \
  zeppelin-service zeppelin

while [ $(kubectl get pod -l app.kubernetes.io/name=zeppelin-server -o jsonpath="{.items[0].status.phase}") != 'Running'  ]; do
  sleep 1
done