#!/bin/bash

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates gnupg jq
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update && sudo apt-get install google-cloud-sdk

if [ "${CIRCLE_BRANCH}" == "main" ]
then
DOCKER_IMAGE_TAG=v${CIRCLE_BUILD_NUM}
echo "$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG" > full_docker_image_name
else
DOCKER_IMAGE_TAG=${CIRCLE_BRANCH}
echo "APP_NAME:$DOCKER_IMAGE_TAG" > full_docker_image_name
fi
FULL_DOCKER_IMAGE_NAME=$(cat full_docker_image_name)
docker build -t $FULL_DOCKER_IMAGE_NAME -f APP_NAME/Dockerfile APP_NAME/

if [ "${CIRCLE_BRANCH}" == "main" ]
then
FULL_DOCKER_IMAGE_NAME=$(cat full_docker_image_name)
echo $GCLOUD_SERVICE_KEY | base64 --decode --ignore-garbage > gcloud-service-key.json
gcloud auth activate-service-account --key-file gcloud-service-key.json
gcloud --quiet auth configure-docker
docker push $FULL_DOCKER_IMAGE_NAME
else
echo "Not main branch; skipping image push.."
fi

FULL_DOCKER_IMAGE_NAME=$(cat full_docker_image_name)
docker run -d --rm -p 8080:8080 --name APP_NAME $FULL_DOCKER_IMAGE_NAME
docker run --network container:APP_NAME appropriate/curl --retry 10 --retry-connrefused http://localhost:8080
if [ "${CIRCLE_BRANCH}" != "main" ]
then
circleci step halt
fi

echo $GCLOUD_SERVICE_KEY | base64 --decode --ignore-garbage > gcloud-service-key.json
set -x
gcloud auth activate-service-account --key-file gcloud-service-key.json
gcloud --quiet config set project $GOOGLE_PROJECT_ID
gcloud --quiet config set compute/zone $GOOGLE_COMPUTE_ZONE
EXISTING_CLUSTER=$(gcloud container clusters list --format="value(name)" --filter="name=$GOOGLE_CLUSTER_NAME")
if [ "${EXISTING_CLUSTER}" != $GOOGLE_CLUSTER_NAME ]
then
# Create cluster if it doesn't already exist
gcloud --quiet container clusters create $GOOGLE_CLUSTER_NAME --num-nodes=1
else
gcloud --quiet container clusters get-credentials $GOOGLE_CLUSTER_NAME
fi
FULL_DOCKER_IMAGE_NAME=$(cat workspace/full_docker_image_name)
# Replace DOCKER_IMAGE_NAME placeholder in manifest with actual image name
KUBE_CONFIG=$(cat APP_NAME/manifests/helloweb-all-in-one.yaml.template | sed "s|DOCKER_IMAGE_NAME|$FULL_DOCKER_IMAGE_NAME|g")
echo "$KUBE_CONFIG" | kubectl apply -f -
# Wait for deployment to finish
kubectl rollout status deployment/helloweb
kubectl get pods

# Wait for external ip to be assigned
sleep 60
kubectl get service helloweb
EXTERNAL_IP=$(kubectl get service helloweb -o json | jq -r ".status.loadBalancer.ingress[0].ip")
curl "http://$EXTERNAL_IP"

if [ "${DELETE_CLUSTER_AT_END_OF_TEST}" == "true" ]
then
kubectl delete service helloweb
gcloud --quiet container clusters delete $GOOGLE_CLUSTER_NAME
fi