#! /bin/bash
CLIENT_SECRET=$1

terraform init
terraform plan -out state.plan
terraform apply "state.plan"
