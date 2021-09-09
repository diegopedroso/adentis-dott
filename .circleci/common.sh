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
    echo "export GKE_ACCESS_KEY_ID=$GKE_ACCESS_KEY_ID_PROD" >> $BASH_ENV
    echo "export GKE_SECRET_ACCESS_KEY=$GKE_SECRET_ACCESS_KEY_PROD" >> $BASH_ENV
    echo "export GKE_CLUSTER_NAME=$PROD_CLUSTER_NAME" >> $BASH_ENV
    echo "export GKE_REGION=$PROD_GKE_REGION" >> $BASH_ENV
  elif [[ "$ENV" == "stg" ]]; then
    echo "export GKE_ACCESS_KEY_ID=$GKE_ACCESS_KEY_ID_STG" >> $BASH_ENV
    echo "export GKE_SECRET_ACCESS_KEY=$GKE_SECRET_ACCESS_KEY_STG" >> $BASH_ENV
    echo "export GKE_CLUSTER_NAME=$STG_CLUSTER_NAME" >> $BASH_ENV
    echo "export GKE_REGION=$STG_GKE_REGION" >> $BASH_ENV
  elif [[ "$ENV" == "qa" ]]; then
    echo "export GKE_ACCESS_KEY_ID=$GKE_ACCESS_KEY_ID_QA" >> $BASH_ENV
    echo "export GKE_SECRET_ACCESS_KEY=$GKE_SECRET_ACCESS_KEY_QA" >> $BASH_ENV
    echo "export GKE_CLUSTER_NAME=$QA_CLUSTER_NAME" >> $BASH_ENV
    echo "export GKE_REGION=$QA_GKE_REGION" >> $BASH_ENV
  fi
  source $BASH_ENV
}

slack_webhook() {
  env_vars
  if [[ "$ENV" == "prod" ]]; then
    echo "export SLACK_WEBHOOK=$SLACK_WEBHOOK_PROD" >> $BASH_ENV && source $BASH_ENV
  elif [[ "$ENV" == "stg" ]]; then
    echo "export SLACK_WEBHOOK=$SLACK_WEBHOOK_STG" >> $BASH_ENV && source $BASH_ENV
  elif [[ "$ENV" == "qa" ]]; then
    echo "export SLACK_WEBHOOK=$SLACK_WEBHOOK_QA" >> $BASH_ENV && source $BASH_ENV
  fi
}