#!/bin/bash

echo """Please wait... 
Tearing down the infrastructure, distroying EC2s, Buckets and Tables."""

cd terraform
terraform destroy -auto-approve >/dev/null 2>&1
cd ..

echo "Would you like to remove the SSH keys? (y/N)"
read user_response
if [[ $user_response == 'y' ]] || [[ $user_response == 'Y' ]]
then
    echo "Removing SSH Key Pair."
    echo "Remember to remove the public key from your GitHub account."
    rm keys/**
    echo ""
else
    echo "Your SSH keys were left in 'project_1/infrastructure/keys/' AND in your GitHub account."
    echo ""
fi

echo "Done."