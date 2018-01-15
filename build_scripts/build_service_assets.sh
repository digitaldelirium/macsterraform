#! /bin/bash

export VAULT_NAME="macscampvault"

export PFX_PASSWORD=`getSecret MacsPFXPassword`
export ACCESS_KEY=`getSecret state-primaryAccessKey`
export SERVER_PK_PASSWORD=`getSecret server-pk-password`
export CLIENT_SECRET=`getSecret client-secret`

# Download Certifcates for Docker
getCertificate MacsVMPrivateKey key.pem
getCertificate MacsVMPublicKey  cert.pem
getCertificate DigitalDeliriumCA cacert.pem

# Get MacsVM SSH Certs
getCertificate MacsSSHPrivateKey macsvm
getCertificate MacsSSHPublicKey macsvm.pub

terraform init -backend-config="access_key=$ACCESS_KEY"
terraform plan -out "service.plan" -var "access_key=$ACCESS_KEY" -var "pfx_password=$PFX_PASSWORD" -var "server_pk_password=$SERVER_PK_PASSWORD"
terraform apply "service.plan"

function getSecret {
    az keyvault secret show $ARG1 --vault-name $VAULT_NAME -o tsv
}

function getCertificate {
    az keyvault secret download $ARG1 --vault-name $VAULT_NAME -f $ARG2
}