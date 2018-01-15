#! /bin/bash
export CLIENT_SECRET=`az keyvault secret show --name client-secret --vault-name macscampvault -o tsv`

terraform init