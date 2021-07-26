#/usr/bin/env sh

set -ex

# The ALLUXIO_UFS and AWS_* env vars need to be setup before running
# In GitLab, these are stored as project variables in Settings -> CI/CD -> Variables

cat << EOF > alluxio.yaml
properties:
    alluxio.master.mount.table.root.ufs: ${ALLUXIO_UFS}
    alluxio.master.mount.table.root.option.aws.accessKeyId: ${AWS_ACCESS_KEY_ID}
    alluxio.master.mount.table.root.option.aws.secretKey: ${AWS_SECRET_ACCESS_KEY}
    alluxio.underfs.s3.default.mode: 777
    alluxio.underfs.s3.inherit.acl: false
    alluxio.security.authentication.type: NOSASL
    alluxio.security.authorization.permission.enabled: false
journal:
    type: UFS
    ufsType: local
    folder: /journal
    size: 1Gi
    volumeType: emptyDir
    medium: ""
master:
    count: 1
shortCircuit:
    enabled: false
tieredstore:
    levels:
    - level: 0
      alias: SSD
      mediumtype: SSD
      path: /ssd
      name: alluxio-ssd
      quota: ${CACHE_SSD_SIZE}
      type: emptyDir
EOF

wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/53/packages/generic/alluxio-helm-chart/0.6.22/alluxio-0.6.22.tgz
tar zxf alluxio-0.6.22.tgz
helm install alluxio -f alluxio.yaml --set journal.format.runFormat=true alluxio/ --wait

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ${MYSQL_SVC_NAME}
spec:
  ports:
  - port: 3306
  selector:
    app: ${MYSQL_SVC_NAME}
  clusterIP: None
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${MYSQL_SVC_NAME}
spec:
  selector:
    matchLabels:
      app: ${MYSQL_SVC_NAME}
  template:
    metadata:
      labels:
        app: ${MYSQL_SVC_NAME}
    spec:
      containers:
      - image: mysql:${MYSQL_VERSION}
        name: ${MYSQL_SVC_NAME}
        env:
          # Use secret in real usage
        - name: MYSQL_ROOT_PASSWORD
          value: ${MYSQL_ROOT_PASSWORD}
        ports:
        - containerPort: 3306
          name: ${MYSQL_SVC_NAME}
EOF

DOCKER_LOGIN_SECRET=login-cred
kubectl create secret docker-registry ${DOCKER_LOGIN_SECRET} --namespace=${KUBE_NAMESPACE} --docker-server=${CI_REGISTRY} --docker-username=${CI_REGISTRY_USER} --docker-password=${CI_REGISTRY_PASSWORD}

wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/50/packages/generic/helm-chart/0.1.0/hive-metastore-0.1.0.tgz
tar xf hive-metastore-0.1.0.tgz

helm upgrade --install \
  --set image.pullSecrets=${DOCKER_LOGIN_SECRET} \
  --set image.registry=${CI_REGISTRY} \
  --set image.repository=sequoiadp/hive-metastore-helmchart \
  --set image.tag=latest \
  hive-metastore-service hive-metastore

wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/34/packages/generic/metadata-helm-chart/0.1.0/helmchart-0.1.0.tgz
tar xf helmchart-0.1.0.tgz

helm upgrade --install \
  --set image.registry=${CI_REGISTRY}/sequoiadp/parquet_metadata_microservice_golang_thrift:latest \
  --set imagePullSecrets="[{\"name\": \"${DOCKER_LOGIN_SECRET}\"}]" \
  metadata-service helmchart

wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/41/packages/generic/zeppelin-helm-chart/0.1.0/zeppelin-0.1.0.tgz
tar xf zeppelin-0.1.0.tgz

helm upgrade --install \
  --set imagePullSecrets="[{\"name\": \"${DOCKER_LOGIN_SECRET}\"}]" \
  --set image.repository=${CI_REGISTRY}/sequoiadp/zeppelin:latest \
  --set image.pullPolicy=IfNotPresent \
  --set spark.repository=${CI_REGISTRY}/sequoiadp/spark:latest \
  zeppelin-service zeppelin

if [[ ${SPARK_HISTORY_SERVER_ENABLED} == "true" ]]; then
  wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" ${CI_API_V4_URL}/projects/55/packages/generic/history-server-helm-chart/0.1.0/history-server-0.1.0.tgz
  tar -zxf history-server-0.1.0.tgz
  helm install history-server --set eventLog.alluxioService=${ALLUXIO_SVC} --set eventLog.dir=${SPARK_EVENTLOG_DIR} history-server/ --wait
fi