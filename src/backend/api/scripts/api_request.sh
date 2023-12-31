#!/bin/bash

# the script allows making a request against the backend api
# i.e., with it you can test the response of the microservices

# required env variables
#AUTH0_DOMAIN, e.g. dev-abcdefg.us.auth0.com
#MACHINE_TO_MACHINE_CLIENT_ID # client for API
#MACHINE_TO_MACHINE_CLIENT_SECRET
#AUDIENCE # should be API_DOMAIN
#API_DOMAIN
#MICROSERVICE_NAME
raw=$(curl -s --request POST \
  --url https://$AUTH0_DOMAIN/oauth/token \
  --header 'content-type: application/json' \
  --data '{"client_id":"$MACHINE_TO_MACHINE_CLIENT_ID","client_secret":"$MACHINE_TO_MACHINE_CLIENT_SECRET","audience":"'$AUDIENCE'","grant_type":"client_credentials"}')

ACCESS_TOKEN=$(echo $raw  | jq '.access_token' | tr -d '"')

echo "ACCESS_TOKEN (base64 decoded):"
echo $ACCESS_TOKEN | base64 -di

echo "API request with access token:"
curl -vs --request GET \
  --url https://$API_DOMAIN/api/$MICROSERVICE_NAME/ \
  --header "authorization: Bearer $ACCESS_TOKEN" > /dev/null

# The below allows testing against the management API
# note that this only works if the requested token has an audience of 
# https://$AUTH0_DOMAIN/api/v2/
#echo "AUTH0 mgmnt API request:"
#curl -s --request GET \
#  --url https://$AUTH0_DOMAIN/api/v2/users \
#  --header "authorization: Bearer $ACCESS_TOKEN"