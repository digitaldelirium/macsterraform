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

az login --service-principal -u 44c4e2a1-4b32-4d7b-b063-ab00907ab449 -p $CLIENT_SECRET --tenant ce30a824-b64b-4702-b3e8-8ff93ba9da38

terraform init -backend-config="access_key=$ACCESS_KEY"
terraform plan -out "service.plan" -var "access_key=$ACCESS_KEY" -var "pfx_password=$PFX_PASSWORD" -var "server_pk_password=$SERVER_PK_PASSWORD"
terraform apply "service.plan"
