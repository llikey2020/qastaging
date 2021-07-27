#/usr/bin/env sh

set -ex

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

while [ $(kubectl get pod -l app=${MYSQL_SVC_NAME} -o jsonpath="{.items[0].status.phase}") != 'Running'  ]; do
  sleep 1
done
