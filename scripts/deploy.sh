#!/bin/bash
echo "PHASE 0: Authenticating to GCP"
#GCP_SECRET=$GOOGLE_CLOUD_KEYFILE_JSON
#unset $GOOGLE_CLOUD_KEYFILE_JSON


echo "PHASE 1: Static infrastructure deployment"
echo "-----------------------------------------"
echo
cd $PROJECT_ROOT/deployment/01_static_infrastructure
#TF_LOG="TRACE" terraform init -reconfigure -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="prefix=$TF_STATE_PREFIX"
terraform init -reconfigure -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="prefix=$TF_STATE_PREFIX"
terraform version
# terraform plan
# if [ $? -ne 0 ]; then
#   echo "Error: Terraform plan failed."
#   exit 1
# fi
# if [ "$CICD" = "true" ]; then
#     echo "CICD environment variable is set to true."
#     echo "Auto approve terraform"
#     terraform apply -auto-approve
# else
#     echo "CICD environment variable is either not set or not true."
#     terraform apply
# fi
#TF_LOG="TRACE" terraform apply -auto-approve
terraform apply -auto-approve
AUTH0_CLIENT_ID=$(terraform output -raw auth0_app_client_id)
API_IP=$(terraform output -raw api_load_balancer_ip)


echo "PHASE 1: Done."
echo

echo "PHASE 2: Static website build and deployment"
echo "--------------------------------------------"
echo

export REACT_APP_AUTH0_CLIENT_ID=$AUTH0_CLIENT_ID
export REACT_APP_AUTH0_DOMAIN=$AUTH0_DOMAIN
export REACT_APP_API=$TF_VAR_api_url
export REACT_APP_AUTH0_REDIRECT_URI=$AUTH0_REDIRECT_URI
export FRONTEND_BUCKET=$FRONTEND_BUCKET
#export GOOGLE_CLOUD_KEYFILE_JSON=$GOOGLE_CLOUD_KEYFILE_JSON

cd $PROJECT_ROOT/src/frontend
# create .env for frontend specific development
echo "export REACT_APP_AUTH0_CLIENT_ID=\"$REACT_APP_AUTH0_CLIENT_ID\"" > .env
echo "export REACT_APP_AUTH0_DOMAIN=\"$REACT_APP_AUTH0_DOMAIN\"" >> .env
echo "export REACT_APP_API=\"$REACT_APP_API\" # expects protocol http or https prefix" >> .env
echo "export REACT_APP_AUTH0_REDIRECT_URI=\"$REACT_APP_AUTH0_REDIRECT_URI\"" >> .env
echo "export FRONTEND_BUCKET=\"$FRONTEND_BUCKET\"" >> .env
#echo "export GOOGLE_CLOUD_KEYFILE_JSON=\"$GOOGLE_CLOUD_KEYFILE_JSON\"" >> .env

./deploy.sh

echo "PHASE 2: Done."
echo

echo "PHASE 3: Docker image build and deployment"
echo "------------------------------------------"
echo


echo "Docker authentication to GCP Artifactory"
gcloud auth configure-docker us-central1-docker.pkg.dev
#cat $GOOGLE_CLOUD_KEYFILE_JSON | docker login -u _json_key --password-stdin https://$DOCKER_REGISTRY

echo "Building and deploying microservices"

echo "Admin Microservice"
cd $PROJECT_ROOT/src/backend/admin
docker build -t $DOCKER_ADMIN .
docker images | head -n 2 | tail -n 1 | awk '{print "Image: " $1":"$2 "\nSize: " $7}'
docker push $DOCKER_ADMIN

echo "Aggregation Microservice"
cd $PROJECT_ROOT/src/backend/aggregation
docker build -t $DOCKER_AGGREGATION .
docker images | head -n 2 | tail -n 1 | awk '{print "Image: " $1":"$2 "\nSize: " $7}'
docker push $DOCKER_AGGREGATION

echo "Data Microservice"
cd $PROJECT_ROOT/src/backend/data
docker build -t $DOCKER_DATA .
docker images | head -n 2 | tail -n 1 | awk '{print "Image: " $1":"$2 "\nSize: " $7}'
docker push $DOCKER_DATA

echo "Ethereum Microservice"
cd $PROJECT_ROOT/src/backend/ethereum
docker build -t $DOCKER_ETHEREUM .
docker images | head -n 2 | tail -n 1 | awk '{print "Image: " $1":"$2 "\nSize: " $7}'
docker push $DOCKER_ETHEREUM

echo "Refresh Microservice"
cd $PROJECT_ROOT/src/backend/refresh
docker build -t $DOCKER_REFRESH .
docker images | head -n 2 | tail -n 1 | awk '{print "Image: " $1":"$2 "\nSize: " $7}'
docker push $DOCKER_REFRESH

echo "PHASE 3: Done."
echo

echo "PHASE 4: Kubernetes Service Deployment"
echo "--------------------------------------"
echo

echo "Services in GKE receive DNS name: servicename.namespacename.svc.cluster.local"



gcloud container clusters get-credentials cluster --region $TF_VAR_gcp_region
kubectl create namespace $KUBERNETES_NAMESPACE


#helm repo add istio https://istio-release.storage.googleapis.com/charts
#helm repo update
#helm install --create-namespace -n istio-system --set defaultRevision=default istio-base istio/base
#helm install istiod istio/istiod -n istio-system --wait
#helm ls -n istio-system



#echo "APISIX Ingress controller"
#
## consider switching to gcp secret store
## terraform state is secured at rest in gcp
## but rotating secret is troublesome
#
#helm repo add apisix https://charts.apiseven.com
#helm repo add bitnami https://charts.bitnami.com/bitnami
#helm repo update
#ADMIN_API_VERSION=v3
#echo "
#helm install apisix apisix/apisix \
#  --set gateway.type=LoadBalancer \
#  --set ingress-controller.enabled=true \
#  --create-namespace \
#  --namespace ingress-apisix \
#  --set ingress-controller.config.apisix.adminKey=$API_ADMIN_PASSWORD \
#  --set admin.credentials.admin=$API_ADMIN_PASSWORD \
#  --set admin.credentials.viewer=$API_VIEWER_PASSWORD \
#  --set ingress-controller.config.apisix.serviceNamespace=ingress-apisix \
#  --set ingress-controller.config.apisix.adminAPIVersion=$ADMIN_API_VERSION
#"
#helm install apisix apisix/apisix \
#  --set gateway.type=LoadBalancer \
#  --set ingress-controller.enabled=true \
#  --create-namespace \
#  --namespace ingress-apisix \
#  --set ingress-controller.config.apisix.adminKey=$API_ADMIN_PASSWORD \
#  --set admin.credentials.admin=$API_ADMIN_PASSWORD \
#  --set admin.credentials.viewer=$API_VIEWER_PASSWORD \
#  --set ingress-controller.config.apisix.serviceNamespace=ingress-apisix \
#  --set ingress-controller.config.apisix.adminAPIVersion=$ADMIN_API_VERSION
#
set -o noglob

values="$PROJECT_ROOT/deployment/02_kubernetes/values.yaml"
deployscript="$PROJECT_ROOT/deployment/02_kubernetes/deploy.sh"
destroyscript="$PROJECT_ROOT/deployment/02_kubernetes/destroy.sh"
statusscript="$PROJECT_ROOT/deployment/02_kubernetes/status.sh"

# TODO: make "api-load-balancer" an env variable, pass to terraform, and replace here
cat << EOF > $values
ingress:
  enabled: true
  className: "gce"
  domain: "$API_DOMAIN"
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "api-load-balancer"
    kubernetes.io/ingress.class: "gce"
    #networking.gke.io/managed-certificates: "api-k8s-tls-certificate"
    kubernetes.io/ingress.allow-http: "true"
    ingress.gcp.kubernetes.io/pre-shared-cert: "api-tls-certificate"
  hosts:
    - host: $API_DOMAIN
      paths:
        - path: /admin
          pathType: Prefix
          backend:
            service:
              name: "$KUBERNETES_BACKEND_RELEASE_NAME-admin"
              port: 80
        - path: /data
          pathType: Prefix
          backend:
            service:
              name: "$KUBERNETES_BACKEND_RELEASE_NAME-data"
              port: 80
        - path: /ethereum
          pathType: Prefix
          backend:
            service:
              name: "$KUBERNETES_BACKEND_RELEASE_NAME-ethereum"
              port: 80
admin:
  image:
    repository: "$DOCKER_ADMIN_IMAGE_FULL_NAME"
    tag: "$DOCKER_ADMIN_TAG"
    pullPolicy: Always
  serviceAccount:
    name: $ADMIN_SERVICE_ACCOUNT_NAME
    annotations:
      iam.gke.io/gcp-service-account: $ADMIN_SERVICE_ACCOUNT_NAME@$GCP_PROJECT_ID.iam.gserviceaccount.com
  #nodeSelector:
  #  iam.gke.io/gke-metadata-server-enabled: "true"
  service:
    type: NodePort # cannot be ServiceIP for Ingress to work
    port: 80
data:
  env:
    - name: SERVICE_NAME
      value: $DOCKER_DATA_IMAGE_NAME
    - name: APP_URL
      value: $APP_URL
    - name: AUTH0_DOMAIN
      value: $AUTH0_DOMAIN
    - name: ETHEREUM_SERVICE_DOMAIN
      value: "$KUBERNETES_BACKEND_RELEASE_NAME-ethereum.$KUBERNETES_NAMESPACE.svc.cluster.local"
    - name: TOKEN_AUDIENCE
      value: $API_URL
  image:
    repository: "$DOCKER_DATA_IMAGE_FULL_NAME"
    tag: "$DOCKER_DATA_TAG"
    pullPolicy: Always
  serviceAccount:
    name: $DATA_SERVICE_ACCOUNT_NAME
    annotations:
      iam.gke.io/gcp-service-account: $DATA_SERVICE_ACCOUNT_NAME@$GCP_PROJECT_ID.iam.gserviceaccount.com
  #nodeSelector:
  #  iam.gke.io/gke-metadata-server-enabled: "true"
  service:
    type: NodePort # cannot be ServiceIP for Ingress to work
    port: 80

ethereum:
  env:
    - name: SERVICE_NAME
      value: $DOCKER_ETHEREUM_IMAGE_NAME
    - name: API_URL
      value: $APP_URL
  secrets:
    - name: ETHERSCAN_API_KEY
      value: "$ETHERSCAN_API_KEY"
  image:
    repository: "$DOCKER_ETHEREUM_IMAGE_FULL_NAME"
    pullPolicy: Always
    tag: "$DOCKER_ETHEREUM_TAG"
  serviceAccount:
    name: $ETHEREUM_SERVICE_ACCOUNT_NAME
    annotations:
      iam.gke.io/gcp-service-account: $ETHEREUM_SERVICE_ACCOUNT_NAME@$GCP_PROJECT_ID.iam.gserviceaccount.com
  #nodeSelector:
  #  iam.gke.io/gke-metadata-server-enabled: "true"
  service:
    type: NodePort # cannot be ServiceIP for Ingress to work
    port: 80
  autoscaling:
    enabled: true
    minReplicas: 1
    maxReplicas: 5
EOF
echo "helm upgrade -i --namespace $KUBERNETES_NAMESPACE -f $values $KUBERNETES_BACKEND_RELEASE_NAME $PROJECT_ROOT/deployment/02_kubernetes/backend" > $deployscript
echo "helm uninstall --namespace $KUBERNETES_NAMESPACE $KUBERNETES_BACKEND_RELEASE_NAME" > $destroyscript
echo "helm upgrade --install --dry-run --debug --namespace $KUBERNETES_NAMESPACE -f $values $KUBERNETES_BACKEND_RELEASE_NAME $PROJECT_ROOT/deployment/02_kubernetes/backend" > $statusscript
echo "kubectl --namespace $KUBERNETES_NAMESPACE describe ingress" >> $statusscript
echo "kubectl --namespace $KUBERNETES_NAMESPACE logs -lapp.kubernetes.io/name={admin,data} --all-containers=true" >> $statusscript
echo "kubectl exec -n $KUBERNETES_NAMESPACE $(kubectl get pods -n $KUBERNETES_NAMESPACE | grep data | cut -f 1 -d ' ') -- env" >> statusscript
echo "kubectl exec -n $KUBERNETES_NAMESPACE $(kubectl get pods -n $KUBERNETES_NAMESPACE | grep admin | cut -f 1 -d ' ') -- env" >> statusscript

helm upgrade \
  --install \
  --namespace $KUBERNETES_NAMESPACE \
  -f $values \
  $KUBERNETES_BACKEND_RELEASE_NAME $PROJECT_ROOT/deployment/02_kubernetes/backend

set +o noglob


#echo "Deploying bastion service"
#set -o noglob
## helm install release_name chartfolder
## we use the convention release_name = service_name
#
#tempfile=$(mktemp)
#cat << EOF > $tempfile
#serviceAccount:
#  annotations:
#    iam.gke.io/gcp-service-account: $BASTION_SERVICE_NAME@$GCP_PROJECT_ID.iam.gserviceaccount.com
#EOF
#
#helm install \
#  --namespace $KUBERNETES_NAMESPACE \
#  --set image.repository=$BASTION_DOCKER_IMAGE \
#  --set image.tag=$BASTION_DOCKER_TAG \
#  --set serviceAccount.name=$BASTION_SERVICE_ACCOUNT_NAME \
#  --set service.type=ClusterIP \
#  -f $tempfile \
#  $BASTION_SERVICE_NAME "$PROJECT_ROOT/src/backend/bastion/helm"
#
#rm -f $tempfile
#set +o noglob

echo "PHASE 4: Done."
echo