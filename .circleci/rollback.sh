#!/bin/bash
set -xe

source ./.circleci/common.sh;
env_vars

gke_credentials

echo $GCLOUD_SERVICE_KEY | base64 --decode --ignore-garbage > gcloud-service-key.json
gcloud auth activate-service-account --key-file gcloud-service-key.json
gcloud --quiet config set project $GOOGLE_PROJECT_ID
gcloud --quiet config set compute/zone $GOOGLE_COMPUTE_ZONE
gcloud --quiet container clusters get-credentials $GOOGLE_CLUSTER_NAME

kubectl rollout undo deployment $APP -n $APP || kubectl_run rollout undo statefulset $APP -n $APP
kubectl rollout status deployment $APP -n $APP || kubectl_run rollout status statefulset $APP -n $APP