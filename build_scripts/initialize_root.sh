#! /bin/bash
CLIENT_SECRET=$1

az login --service-principal -u 44c4e2a1-4b32-4d7b-b063-ab00907ab449 -p $CLIENT_SECRET --tenant ce30a824-b64b-4702-b3e8-8ff93ba9da38

terraform init