#! /bin/bash
CLIENT_SECRET=$1
ACCESS_KEY=$2

cd ../state

terraform init -backend-config="access_key=$ACCESS_KEY"
terraform plan -out state.plan
terraform apply "state.plan"
