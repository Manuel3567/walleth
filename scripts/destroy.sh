#!/bin/bash

echo "PHASE 1: Deleting static infrastructure"
echo "---------------------------------------"
echo
SCRIPT_DIR=$(dirname $0)
export PROJECT_ROOT=$(cd $SCRIPT_DIR && cd .. && pwd)

cd $PROJECT_ROOT/deployment/01_static_infrastructure
terraform init -reconfigure -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="prefix=$TF_STATE_PREFIX"
terraform destroy -auto-approve
#targets=$(terraform state list | egrep -v "key\.|key_ring|data\." | awk '{printf "--target %s ", $0}')
#eval "terraform destroy $targets"
echo "PHASE 1: Done."
echo