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

helm repo add alluxio-charts https://alluxio-charts.storage.googleapis.com/openSource/2.6.0
helm install alluxio -f alluxio.yaml alluxio-charts/alluxio --wait

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
