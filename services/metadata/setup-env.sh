#/usr/bin/env sh

set -ex

METADATA_DOCKER_LOGIN_SECRET=metadata-login-cred
kubectl create secret docker-registry ${METADATA_DOCKER_LOGIN_SECRET} --namespace=${KUBE_NAMESPACE} --docker-server=${CI_REGISTRY} --docker-username=${CI_REGISTRY_USER} --docker-password=${CI_REGISTRY_PASSWORD}

wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/34/packages/generic/metadata-helm-chart/0.1.0/helmchart-0.1.0.tgz
tar xf helmchart-0.1.0.tgz

helm upgrade --install \
  --set image.registry=${CI_REGISTRY}/sequoiadp/metadata_service:latest \
  --set imagePullSecrets="[{\"name\": \"${METADATA_DOCKER_LOGIN_SECRET}\"}]" \
  metadata-service helmchart

while [ $(kubectl get pod -l app=metadata-microservice -o jsonpath="{.items[0].status.phase}") != 'Running'  ]; do
  sleep 1
done
