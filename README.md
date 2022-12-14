# SequoiaDP staging environment project

## Overview

The staging pipeline is used to deploy SequoiaDP services in our staging environment, and consists of several stages. The prepare stage downloads the packaged Helm charts for each service from their respective GitLab project's package repository, and Helm values are customized for the services in the form of a generated `overrides.yml` file. This file is used when running `helm upgrade --install ...` in the deploy stage.

## Deploying services

To deploy a service, trigger the staging pipeline through the CI/CD > Pipelines page in the staging project, via the 'Run Pipeline' button. The specific service to deploy can be specified using the DEPLOY_PROJECT variable. Multiple services to deploy can be specified as a **comma separated list**, or the variable can be set to 'all' to redeploy every service. See the DEPLOY_PROJECT variable description on the 'Run Pipeline' page for the various service name options.

If the service was already present in the staging environment, triggering the pipeline will only successfully redeploy the service if the commit SHA of the latest master commit has changed for that service's project, or if helm chart for the service has been modified. Otherwise, the previously deployed version of the service will remain unchanged.

You can also specify the specific commit for the service image, by setting the relevant image tag variable to the specific commit SHA, e.g. setting `BATCH_JOB_IMAGE_TAG` as `6c6275218a4781d197ab02c6ecfa5259838d7d26`.

Deployed services pull docker images using the `docker-login` kubernetes secret present in the staging environment. Services can be connected to using the service name and port, which can be found in the `services/*.yml` file for each service.


## Verifying services are running

### Deployed services can be accesed at:  http://staging.planetrover.ca:32499


### Downstream pipeline

Currently, the following services trigger a downstream pipeline in Staging:

- Metadata Service

This pipeline deploys a separate test version of the service in the staging environment, as well as a separate test version of the MySQL service if needed. It then verifies that the newly deployed service's pods start running successfully. This test version does **not** affect the services normally deployed in staging, and is based on the version of the helm chart and docker image created by the specific upstream commit that triggered this downstream deploy.

Downstream pipelines may be implemented for more services in the future. Note that CI pipelines cannot be run simultaneously in the Staging environment, so be careful to avoid conflicts between developers using the Staging environment at the same time.

## Cleaning up services

### Triggering clean up jobs

You can trigger the staging clean up job by manually triggering a pipeline in staging through 'Run Pipeline' and setting the variable ONLY_CLEANUP to 'true'.  **Note that this action deletes all services running in the staging environment, and is therefore rarely run.**

The clean up job for downstream pipelines is also manually triggered, and can be found in the last stage of the downstream pipeline. This job only deletes the services created by the downstream pipeline.

## Related projects

Projects whose CI pipelines extend this project:

- AWS Deploy
- Performance
