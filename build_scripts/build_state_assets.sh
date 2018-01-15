#! /bin/bash
CLIENT_SECRET=$1

cd ../state

terraform init
terraform plan -out state.plan
terraform apply "state.plan"
