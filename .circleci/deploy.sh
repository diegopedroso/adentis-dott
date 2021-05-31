#!/bin/bash
set -xe

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates gnupg jq kubectl google-cloud-sdk

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