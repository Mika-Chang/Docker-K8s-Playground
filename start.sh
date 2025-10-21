#!/usr/bin/bash
rm terraform.tfstate
rm -f docker-key.pem
rm docker-key.pem.pub
./make_key.sh

echo "Creating resources"
terraform apply --auto-approve

# Sleep prevents sshing before docker is set up
echo "Sleeping 2 minutes to allow user data to apply"
sleep 120
/usr/bin/bash connect.sh
