#!/bin/bash
set -xe
source ./.circleci/common.sh;

# Load common functions

env_vars
gke_credentials

# Install dependencies

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates gnupg jq kubectl google-cloud-sdk

# Build Docker Image

docker build -t eu.gcr.io/$GOOGLE_PROJECT_ID/$APP:$TAG -f apps/$APP/Dockerfile apps/$APP
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

# Replace $APP placeholder in manifest with actual image name
KUBE_CONFIG=$(cat apps/$APP/kubernetes/$ENV-values.yaml | sed "s|CIRCLE_TAG_REPLACE|$TAG|g")
echo "$KUBE_CONFIG" | kubectl apply -f -
# Wait for deployment to finish
kubectl rollout status deployment/$APP -n $APP
kubectl get pods -n $APP

# Wait for external ip to be assigned
sleep 30
kubectl get service $APP -n $APP
# Use for Load Balancer instead internal services
# EXTERNAL_IP=$(kubectl get service $APP -n $APP -o json | jq -r ".status.loadBalancer.ingress[0].ip")
# curl "http://$EXTERNAL_IP"
#CLUSTER-IP=$(kubectl get service $APP -n $APP -o json | jq -r ".spec.clusterIP")
# curl "http://$CLUSTER-IP"
