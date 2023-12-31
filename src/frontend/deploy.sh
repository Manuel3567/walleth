#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the script directory
cd "$SCRIPT_DIR"

source .env

# Check if the FRONTEND_BUCKET environment variable is set
if [ -z "$FRONTEND_BUCKET" ]; then
  echo "Error: FRONTEND_BUCKET environment variable is not set."
  exit 1
fi

# Set the correct directory containing the build files (CRA uses "build" by default)
BUILD_DIR="build"

# Remove existing build folder if present
if [ -d "$BUILD_DIR" ]; then
  echo "Removing existing build folder..."
  rm -rf "$BUILD_DIR"
fi

# Run npm build
npm run build

# Check if npm run build was successful
if [ $? -ne 0 ]; then
  echo "Error: npm run build failed."
  exit 1
fi

# Check if the build directory exists
if [ ! -d "$BUILD_DIR" ]; then
  echo "Error: Build directory '$BUILD_DIR' not found."
  exit 1
fi

# Upload files to Google Cloud Storage
if [ -z "$GOOGLE_CLOUD_KEYFILE_JSON" ]; then
  echo "Error: GOOGLE_CLOUD_KEYFILE_JSON environment variable is not set. Path to json is required for authentication."
  exit 1
fi
gcloud auth activate-service-account --key-file $GOOGLE_CLOUD_KEYFILE_JSON
gsutil -m rsync -d -r "$BUILD_DIR" "gs://$FRONTEND_BUCKET"

# Check if upload was successful
if [ $? -ne 0 ]; then
  echo "Error: Upload to Google Cloud Storage failed."
  exit 1
fi

echo "Deployment successful. Your website is now available at:"
echo "https://$FRONTEND_BUCKET.storage.googleapis.com/"
