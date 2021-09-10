#!/bin/bash

env_vars() {
  echo "export APP=$(echo $CIRCLE_TAG | awk -F "(/)" '{print $1}')" >> $BASH_ENV
  echo "export ENV=$(echo $CIRCLE_TAG | awk -F "(/)" '{print $2}' | awk -F "(-)" '{print $1}')" >> $BASH_ENV
  echo "export TAG=$(echo $CIRCLE_TAG | awk -F "(/)" '{print $2}')" >> $BASH_ENV
  source $BASH_ENV
}

gke_credentials() {
  env_vars
  if [[ "$ENV" == "prod" ]]; then
    echo "export GKE_ACCESS_KEY_ID=$GCLOUD_SERVICE_KEY" >> $BASH_ENV
    echo "export GKE_CLUSTER_NAME=$GOOGLE_CLUSTER_NAME" >> $BASH_ENV
    echo "export GKE_REGION=$PROD_GKE_REGION" >> $BASH_ENV
  elif [[ "$ENV" == "stg" ]]; then
    echo "export GKE_ACCESS_KEY_ID=$GCLOUD_SERVICE_KEY" >> $BASH_ENV
    echo "export GKE_CLUSTER_NAME=$GOOGLE_CLUSTER_NAME" >> $BASH_ENV
    echo "export GOOGLE_PROJECT_ID=$GOOGLE_PROJECT_ID" >> $BASH_ENV
    echo "export GKE_REGION=$GOOGLE_COMPUTE_ZONE" >> $BASH_ENV
  fi
  source $BASH_ENV
}

slack_webhook() {
  env_vars
  if [[ "$ENV" == "prod" ]]; then
    echo "export SLACK_WEBHOOK=$SLACK_WEBHOOK_PROD" >> $BASH_ENV && source $BASH_ENV
  elif [[ "$ENV" == "stg" ]]; then
    echo "export SLACK_WEBHOOK=$SLACK_WEBHOOK_STG" >> $BASH_ENV && source $BASH_ENV
  fi
}