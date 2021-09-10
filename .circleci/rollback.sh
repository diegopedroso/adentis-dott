#!/bin/bash
set -xe

source ./.circleci/common.sh;
source ./.circleci/deploy.sh;
env_vars

gke_credentials

echo $GCLOUD_SERVICE_KEY | base64 --decode --ignore-garbage > gcloud-service-key.json
gcloud auth activate-service-account --key-file gcloud-service-key.json
gcloud --quiet auth configure-docker
docker push eu.gcr.io/$GOOGLE_PROJECT_ID/$APP:$TAG

docker run -d --rm -p 8080:8080 --name $APP eu.gcr.io/$GOOGLE_PROJECT_ID/$APP:$TAG
docker run --network container:$APP appropriate/curl --retry 10 --retry-connrefused http://localhost:8080

echo $GCLOUD_SERVICE_KEY | base64 --decode --ignore-garbage > gcloud-service-key.json
set -x
gcloud auth activate-service-account --key-file gcloud-service-key.json
gcloud --quiet config set project $GOOGLE_PROJECT_ID
gcloud --quiet config set compute/zone $GOOGLE_COMPUTE_ZONE
gcloud --quiet container clusters get-credentials $GOOGLE_CLUSTER_NAME

kubectl rollout undo deployment $APP -n $APP || kubectl_run rollout undo statefulset $APP -n $APP
kubectl rollout status deployment $APP -n $APP || kubectl_run rollout status statefulset $APP -n $APP