#!/bin/bash

cd $PROJECT_DIR/infrastructure
terraform init -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="prefix=$TF_STATE_PREFIX"
terraform plan
if [ $? -ne 0 ]; then
  echo "Error: Terraform plan failed."
  exit 1
fi
if [ "$CICD" = "true" ]; then
    echo "CICD environment variable is set to true."
    echo "Auto approve terraform"
    terraform apply -auto-approve
else
    echo "CICD environment variable is either not set or not true."
    terraform apply
fi

AUTH0_CLIENT_ID=$(terraform output -raw auth0_app_client_id)
echo "From Terraform extracted AUTH0 client id: $AUTH0_CLIENT_ID"


export REACT_APP_AUTH0_CLIENT_ID=$AUTH0_CLIENT_ID
export REACT_APP_AUTH0_DOMAIN=$AUTH0_DOMAIN
export REACT_APP_API=$TF_VAR_api_url
export REACT_APP_AUTH0_REDIRECT_URI=$AUTH0_REDIRECT_URI
export FRONTEND_BUCKET=$FRONTEND_BUCKET
export GOOGLE_CLOUD_KEYFILE_JSON=$GOOGLE_CLOUD_KEYFILE_JSON

cd $PROJECT_DIR/src/frontend
# create .env for frontend specific development
echo "export REACT_APP_AUTH0_CLIENT_ID=\"$REACT_APP_AUTH0_CLIENT_ID\"" > .env
echo "export REACT_APP_AUTH0_DOMAIN=\"$REACT_APP_AUTH0_DOMAIN\"" >> .env
echo "export REACT_APP_API=\"$REACT_APP_API\" # expects protocol http or https prefix" >> .env
echo "export REACT_APP_AUTH0_REDIRECT_URI=\"$REACT_APP_AUTH0_REDIRECT_URI\"" >> .env
echo "export FRONTEND_BUCKET=\"$FRONTEND_BUCKET\"" >> .env
echo "export GOOGLE_CLOUD_KEYFILE_JSON=\"$GOOGLE_CLOUD_KEYFILE_JSON\"" >> .env

./deploy.sh