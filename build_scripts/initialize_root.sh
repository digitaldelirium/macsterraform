#! /bin/bash
CLIENT_SECRET=$1

az login --msi

terraform init