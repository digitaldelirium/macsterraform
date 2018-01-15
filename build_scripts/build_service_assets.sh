#! /bin/bash
export CLIENT_SECRET=$1
export PFX_PASSWORD=$2
export ACCESS_KEY=$3
export SERVER_PK_PASSWORD=$4
export SERVER_PRIVATE_KEY=$5
export SERVER_PUBLIC_KEY=$6
export CA_CERT=$7
export SSH_PRIVATE_KEY=$8
export SSH_PUBLIC_KEY=$9
export SSH_PASSPHRASE=$10

# Create Key.Pem
echo $SERVER_PRIVATE_KEY > key.pem
chmod 400 key.pem

# Create Cert.pem
echo $SERVER_PUBLIC_KEY > cert.pem

# Create CA Cert
echo $CA_CERT > cacert.pem

echo $SSH_PRIVATE_KEY > macsvm
chmod 400 macsvm

echo $SSH_PUBLIC_KEY > macsvm.pub

az login --msi

terraform init -backend-config="access_key=$ACCESS_KEY"
terraform plan -out "service.plan" -var "access_key=$ACCESS_KEY" -var "pfx_password=$PFX_PASSWORD" -var "server_pk_password=$SERVER_PK_PASSWORD"
terraform apply "service.plan"
