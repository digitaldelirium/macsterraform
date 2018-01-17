#! /bin/bash
CLIENT_SECRET=$1
CLIENT_ID=$2
TENANT_ID=$3

az login --service-principal -u $2 --password $1 --tenant $3

terraform init -var client_secret=$CLIENT_SECRET
