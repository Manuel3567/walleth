#!/bin/bash

echo "PHASE 1: Deleting static infrastructure"
echo "---------------------------------------"
echo
cd $PROJECT_ROOT/deployment/01_static_infrastructure
#terraform destroy -auto-approve
# TODO: remove the kms keyring and key from this terraform deployment.
targets=$(terraform state list | egrep -v "key\.|key_ring|data\." | awk '{printf "--target %s ", $0}')
eval "terraform destroy $targets"
echo "PHASE 1: Done."
echo