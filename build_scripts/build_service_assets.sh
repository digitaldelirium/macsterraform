#! /bin/bash
export CLIENT_SECRET=$1
export PFX_PASSWORD=$2
export ACCESS_KEY=$3
export SERVER_PK_PASSWORD=$4

cd ../service

# Create Key.Pem
echo $5 > key.pem
chmod 400 key.pem

# Create Cert.pem
echo $6 > cert.pem

# Create CA Cert
echo $7 > cacert.pem

echo $8 > macsvm
chmod 400 macsvm

echo $9 > macsvm.pub

terraform init -backend-config="access_key=$ACCESS_KEY"
terraform plan -out "service.plan" -var "access_key=$ACCESS_KEY" -var "pfx_password=$PFX_PASSWORD" -var "server_pk_password=$SERVER_PK_PASSWORD"
terraform apply "service.plan"
