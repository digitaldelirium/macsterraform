#! /bin/bash
export CLIENT_SECRET=`az keyvault secret show --name client-secret --vault-name macscampvault -o tsv`

terraform init
terraform plan -out state.plan
terraform apply "state.plan"
