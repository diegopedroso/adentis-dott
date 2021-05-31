echo $GCLOUD_SERVICE_KEY | base64 --decode --ignore-garbage > gcloud-service-key.json
set -x
gcloud auth activate-service-account --key-file gcloud-service-key.json
gcloud --quiet config set project $GOOGLE_PROJECT_ID
gcloud --quiet config set compute/zone $GOOGLE_COMPUTE_ZONE
gcloud --quiet container clusters get-credentials $GOOGLE_CLUSTER_NAME

FULL_DOCKER_IMAGE_NAME=$(cat full_docker_image_name)
# Replace DOCKER_IMAGE_NAME placeholder in manifest with actual image name
KUBE_CONFIG=$(cat APP_NAME/manifests/helloweb-all-in-one.yaml.template | sed "s|DOCKER_IMAGE_NAME|$FULL_DOCKER_IMAGE_NAME|g")
echo "$KUBE_CONFIG" | kubectl apply -f -
# Wait for deployment to finish
kubectl rollout status deployment/APP_NAME
kubectl get pods

# Wait for external ip to be assigned
sleep 60
kubectl get service APP_NAME
EXTERNAL_IP=$(kubectl get service APP_NAME -o json | jq -r ".status.loadBalancer.ingress[0].ip")
curl "http://$EXTERNAL_IP"

if [ "${DELETE_CLUSTER_AT_END_OF_TEST}" == "true" ]
then
kubectl delete service APP_NAME
gcloud --quiet container clusters delete $GOOGLE_CLUSTER_NAME
fi
