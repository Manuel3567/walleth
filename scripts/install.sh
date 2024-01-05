#!/bin/bash

# auth plugin kubernetes
echo "Installing gke auth plugin..." 

#gcloud components install gke-gcloud-auth-plugin
#sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin

gke-gcloud-auth-plugin --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Failed to install gke auth plugin."
  exit 1
else
  echo "Successfully installed gke auth plugin."
fi
