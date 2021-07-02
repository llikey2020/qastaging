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

# The metadata microservice must be built before installing
git pull https://gitlab.planetrover.io/sequoiadp/parquet_metadata_microservice_golang_thrift.git
cd parquet_metadata_microservice_golang_thrift/src
thrift -r --gen go metadata.thrift
 cd gen-go
    # Initialize generated go modules
for i in parquet_metadata metadata
do
    cd $i
    go mod init $i
    go mod tidy
    sed -i "s/github.com\/apache\/thrift\/lib\/go\/thrift v0.0.0-20210120171102-e27e82c46ba4/github.com\/apache\/thrift v0.13.0/g" go.mod
    cd ..
done
# Insert reference to image pull secret into deployment yaml
cd ../..
"sed -i \"s@# <CI image secret is inserted here by pipeline in the helm build job>@imagePullSecrets:\\n      - name: login-cred@g\" helmchart/templates/my-image.yaml"
# Replace image with gitlab registry image url
sed -i "s@metadata_microserivce_demo:latest@${CI_REGISTRY_IMAGE}:latest@g" helmchart/templates/my-image.yaml
# Generate imae pull secret using gitlab registry credentials
kubectl create secret docker-registry login-cred --namespace=${KUBE_NAMESPACE} --docker-server=${CI_REGISTRY} --docker-username=${CI_REGISTRY_USER} --docker-password=${CI_REGISTRY_PASSWORD}
helm upgrade --install metadata-microservice ./helmchart
    
# run metastore microservice
