#!/bin/bash


# List of environment variables to check
# Get the 3 auth0 envs from the Auth0 Account Management API Management Client (auth0 app)
# they are used by terraform to deploy apps, and APIs
env_vars=(
    "PROJECT_ROOT"
    "GCP_PROJECT_ID"
    "GCP_REGION"
    "APP_DOMAIN"
    "APP_VERSION"
    "AUTH0_DOMAIN"
    "AUTH0_CLIENT_ID"
    "AUTH0_CLIENT_SECRET"
    "CICD"
)

SCRIPT_DIR=$(dirname $0)
export PROJECT_ROOT=$(cd $SCRIPT_DIR && cd .. && pwd)

file_path="$PROJECT_ROOT/.env.in"
echo $file_path

if [ -e "$file_path" ]; then
  echo "File exists: $file_path"
  echo "Sourcing variables"
  source $file_path
else
  echo "File does not exist: $file_path"
  echo "Assumes following variables are set externally"
fi


# Function to check if an environment variable is set and not empty
check_env_variable() {
  if [[ -n "${!1}" ]]; then
    echo "Variable $1 is set"
  else
    echo "Variable $1 is not set or is empty"
    exit 1
  fi
}

# Check each environment variable
for var in "${env_vars[@]}"; do
  check_env_variable "$var"
done


GOOGLE_CLOUD_KEYFILE_JSON="$PROJECT_ROOT/secrets/gcp.json"
if [ -e "$GOOGLE_CLOUD_KEYFILE_JSON" ]; then
  echo "File exists: $GOOGLE_CLOUD_KEYFILE_JSON"
else
  echo "File does not exist: $GOOGLE_CLOUD_KEYFILE_JSON"
  echo "Get credentials from GCP..."
  exit 1
fi

 
env_out_file="$PROJECT_ROOT/.env.out"
if [ -e "$env_out_file" ]; then
  echo "File exists: $env_out_file"
  echo "Aborting. Delete file first if you want to regenerate."
  exit 1
else
  echo "File does not exist: $env_out_file"
  echo "Generating $env_out_file file"
fi




APP_URL="https://$APP_DOMAIN"
API_DOMAIN="api.$APP_DOMAIN"
API_URL="https://$API_DOMAIN"
FRONTEND_BUCKET="frontend-$GCP_PROJECT_ID"
AUTH0_REDIRECT_URI="$APP_URL"
GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_CLOUD_KEYFILE_JSON"
CLOUDSDK_CORE_PROJECT="$GCP_PROJECT_ID"
DOCKER_REGISTRY="$GCP_REGION-docker.pkg.dev"
ARTIFACTORY_DOCKER_REPOSITORY_NAME="docker"
DOCKER_REPOSITORY="$DOCKER_REGISTRY/$GCP_PROJECT_ID/$ARTIFACTORY_DOCKER_REPOSITORY_NAME"
KUBERNETES_NAMESPACE="dev"
TF_VAR_kubernetes_namespace="$KUBERNETES_NAMESPACE"
KUBERNETES_BACKEND_RELEASE_NAME="backend"
DOCKER_DATA_IMAGE_NAME="data"
DATA_SERVICE_ACCOUNT_NAME="dataservice"
DOCKER_DATA_TAG="$APP_VERSION"
DOCKER_DATA_IMAGE_FULL_NAME="$DOCKER_REPOSITORY/$DOCKER_DATA_IMAGE_NAME"
DOCKER_DATA="$DOCKER_DATA_IMAGE_FULL_NAME:$DOCKER_DATA_TAG"
TF_VAR_data_service_account_name="$DATA_SERVICE_ACCOUNT_NAME"
DOCKER_AGGREGATION_IMAGE_NAME="aggregation"
AGGREGATION_SERVICE_ACCOUNT_NAME="aggregationservice"
DOCKER_AGGREGATION_TAG="$APP_VERSION"
DOCKER_AGGREGATION_IMAGE_FULL_NAME="$DOCKER_REPOSITORY/$DOCKER_AGGREGATION_IMAGE_NAME"
DOCKER_AGGREGATION="$DOCKER_AGGREGATION_IMAGE_FULL_NAME:$DOCKER_AGGREGATION_TAG"
TF_VAR_aggregation_service_account_name="$AGGREGATION_SERVICE_ACCOUNT_NAME"
DOCKER_ADMIN_IMAGE_NAME="admin"
ADMIN_SERVICE_ACCOUNT_NAME="adminservice"
DOCKER_ADMIN_TAG="$APP_VERSION"
DOCKER_ADMIN_IMAGE_FULL_NAME="$DOCKER_REPOSITORY/$DOCKER_ADMIN_IMAGE_NAME"
DOCKER_ADMIN="$DOCKER_ADMIN_IMAGE_FULL_NAME:$DOCKER_ADMIN_TAG"
TF_VAR_admin_service_account_name="$ADMIN_SERVICE_ACCOUNT_NAME"
DOCKER_ETHEREUM_IMAGE_NAME="ethereum"
ETHEREUM_SERVICE_ACCOUNT_NAME="ethereumservice"
DOCKER_ETHEREUM_TAG="$APP_VERSION"
DOCKER_ETHEREUM_IMAGE_FULL_NAME="$DOCKER_REPOSITORY/$DOCKER_ETHEREUM_IMAGE_NAME"
DOCKER_ETHEREUM="$DOCKER_ETHEREUM_IMAGE_FULL_NAME:$DOCKER_ETHEREUM_TAG"
TF_VAR_ethereum_service_account_name="$ETHEREUM_SERVICE_ACCOUNT_NAME"
DOCKER_REFRESH_IMAGE_NAME="refresh"
REFRESH_SERVICE_ACCOUNT_NAME="refreshservice"
DOCKER_REFRESH_TAG="$APP_VERSION"
DOCKER_REFRESH_IMAGE_FULL_NAME="$DOCKER_REPOSITORY/$DOCKER_REFRESH_IMAGE_NAME"
DOCKER_REFRESH="$DOCKER_REFRESH_IMAGE_FULL_NAME:$DOCKER_REFRESH_TAG"
TF_VAR_refresh_service_account_name="$REFRESH_SERVICE_ACCOUNT_NAME"
TF_STATE_BUCKET="terraform-state-etherapp-408410" # manually created
TF_STATE_PREFIX="terraform/state"
TF_VAR_gcp_project_id="$GCP_PROJECT_ID"
TF_VAR_gcp_region="$GCP_REGION"
TF_VAR_gcp_default_zone="us-central1-c"
TF_VAR_frontend_bucket="$FRONTEND_BUCKET"
TF_VAR_frontend_bucket_location="US-CENTRAL1"
TF_VAR_app_url="$APP_URL"
TF_VAR_app_domain="$APP_DOMAIN"
TF_VAR_api_url="$API_URL"
TF_VAR_api_domain="$API_DOMAIN"
TF_VAR_auth0_redirect_uri="$AUTH0_REDIRECT_URI"
TF_VAR_docker_repository_name="$ARTIFACTORY_DOCKER_REPOSITORY_NAME"

cat << EOF > $env_out_file
# general
export PROJECT_ROOT="$PROJECT_ROOT"
export GCP_PROJECT_ID="$GCP_PROJECT_ID"
export GCP_REGION="$GCP_REGION"

export APP_DOMAIN="$APP_DOMAIN"
# Get the 3 auth0 envs from the Auth0 Account Management API Management Client (auth0 app)
# they are used by terraform to deploy apps, and APIs
export AUTH0_DOMAIN="$AUTH0_DOMAIN"
export AUTH0_CLIENT_ID="$AUTH0_CLIENT_ID"
export AUTH0_CLIENT_SECRET="$AUTH0_CLIENT_SECRET"
export GOOGLE_CLOUD_KEYFILE_JSON="$GOOGLE_CLOUD_KEYFILE_JSON" # for deploying infra and managing state 



# app
export APP_URL="https://$APP_DOMAIN"
export API_DOMAIN="api.$APP_DOMAIN"
export API_URL="https://$API_DOMAIN"
export FRONTEND_BUCKET="frontend-$GCP_PROJECT_ID"
export AUTH0_REDIRECT_URI="$APP_URL"



# extra APPLICATION_CREDENTIALS env variable needed for backend init
# see: https://github.com/terraform-google-modules/cloud-foundation-training/issues/15
export GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_CLOUD_KEYFILE_JSON" 
# used by gcloud
export CLOUDSDK_CORE_PROJECT="$GCP_PROJECT_ID"



# CICD
export CICD="$CICD"



# Docker Repos
export DOCKER_REGISTRY="$GCP_REGION-docker.pkg.dev"
export ARTIFACTORY_DOCKER_REPOSITORY_NAME="docker"
export DOCKER_REPOSITORY="$DOCKER_REGISTRY/$GCP_PROJECT_ID/$ARTIFACTORY_DOCKER_REPOSITORY_NAME"


# Kubernetes
export KUBERNETES_NAMESPACE="$KUBERNETES_NAMESPACE"
export TF_VAR_kubernetes_namespace="$KUBERNETES_NAMESPACE"
export KUBERNETES_BACKEND_RELEASE_NAME="backend"
## Services


### data
export DOCKER_DATA_IMAGE_NAME="data"
export DATA_SERVICE_ACCOUNT_NAME="dataservice"
export DOCKER_DATA_TAG="$APP_VERSION"
export DOCKER_DATA_IMAGE_FULL_NAME="$DOCKER_REPOSITORY/$DOCKER_DATA_IMAGE_NAME"
export DOCKER_DATA="$DOCKER_DATA_IMAGE_FULL_NAME:$DOCKER_DATA_TAG"
export TF_VAR_data_service_account_name="$DATA_SERVICE_ACCOUNT_NAME"

### aggregation
export DOCKER_AGGREGATION_IMAGE_NAME="aggregation"
export AGGREGATION_SERVICE_ACCOUNT_NAME="aggregationservice"
export DOCKER_AGGREGATION_TAG="$APP_VERSION"
export DOCKER_AGGREGATION_IMAGE_FULL_NAME="$DOCKER_REPOSITORY/$DOCKER_AGGREGATION_IMAGE_NAME"
export DOCKER_AGGREGATION="$DOCKER_AGGREGATION_IMAGE_FULL_NAME:$DOCKER_AGGREGATION_TAG"
export TF_VAR_aggregation_service_account_name="$AGGREGATION_SERVICE_ACCOUNT_NAME"

### admin
export DOCKER_ADMIN_IMAGE_NAME="admin"
export ADMIN_SERVICE_ACCOUNT_NAME="adminservice"
export DOCKER_ADMIN_TAG="$APP_VERSION"
export DOCKER_ADMIN_IMAGE_FULL_NAME="$DOCKER_REPOSITORY/$DOCKER_ADMIN_IMAGE_NAME"
export DOCKER_ADMIN="$DOCKER_ADMIN_IMAGE_FULL_NAME:$DOCKER_ADMIN_TAG"
export TF_VAR_admin_service_account_name="$ADMIN_SERVICE_ACCOUNT_NAME"

### ethereum
export DOCKER_ETHEREUM_IMAGE_NAME="ethereum"
export ETHEREUM_SERVICE_ACCOUNT_NAME="ethereumservice"
export DOCKER_ETHEREUM_TAG="$APP_VERSION"
export DOCKER_ETHEREUM_IMAGE_FULL_NAME="$DOCKER_REPOSITORY/$DOCKER_ETHEREUM_IMAGE_NAME"
export DOCKER_ETHEREUM="$DOCKER_ETHEREUM_IMAGE_FULL_NAME:$DOCKER_ETHEREUM_TAG"
export TF_VAR_ethereum_service_account_name="$ETHEREUM_SERVICE_ACCOUNT_NAME"

### refresh
export DOCKER_REFRESH_IMAGE_NAME="refresh"
export REFRESH_SERVICE_ACCOUNT_NAME="refreshservice"
export DOCKER_REFRESH_TAG="$APP_VERSION"
export DOCKER_REFRESH_IMAGE_FULL_NAME="$DOCKER_REPOSITORY/$DOCKER_REFRESH_IMAGE_NAME"
export DOCKER_REFRESH="$DOCKER_REFRESH_IMAGE_FULL_NAME:$DOCKER_REFRESH_TAG"
export TF_VAR_refresh_service_account_name="$REFRESH_SERVICE_ACCOUNT_NAME"

# Terraform
export TF_STATE_BUCKET="terraform-state-etherapp-408410" # manually created
export TF_STATE_PREFIX="terraform/state"

export TF_VAR_gcp_project_id="$GCP_PROJECT_ID"
export TF_VAR_gcp_region="$GCP_REGION"
export TF_VAR_gcp_default_zone="us-central1-c"
export TF_VAR_frontend_bucket="$FRONTEND_BUCKET"
export TF_VAR_frontend_bucket_location="US-CENTRAL1"

export TF_VAR_app_url="$APP_URL"
export TF_VAR_app_domain="$APP_DOMAIN"
export TF_VAR_api_url="$API_URL"
export TF_VAR_api_domain="$API_DOMAIN"
export TF_VAR_auth0_redirect_uri="$AUTH0_REDIRECT_URI"
export TF_VAR_docker_repository_name="$ARTIFACTORY_DOCKER_REPOSITORY_NAME"
EOF