#!/bin/bash

#### Pre-install info gathering ####

## Getting aws keys 
echo "Scanning for aws keys"
if [ ! -f ~/.aws/credentials ]
    then
        echo "AWS Credentials file is missing, run 'aws configure'."
        echo "File expexted at ~/.aws/credentials but is not there."
        exit 1
fi
echo "AWS Credentials file found and being parsed."

## Parsing AWS Creds.
INI_FILE=~/.aws/credentials
while IFS=' = ' read key value
do
    if [[ $key == \[*] ]]; then
        section=$key
    elif [[ $value ]] && [[ $section == '[default]' ]]; then
        if [[ $key == 'aws_access_key_id' ]]; then
            AWS_ACCESS_KEY_ID=$value
        elif [[ $key == 'aws_secret_access_key' ]]; then
            AWS_SECRET_ACCESS_KEY=$value
        fi
    fi
done < $INI_FILE

awsID=${AWS_ACCESS_KEY_ID}
awsSECRET=${AWS_SECRET_ACCESS_KEY}
gitEmail=$(git config --global user.email)

## Create RSA key pair
echo "Creating SSH keys."
mkdir -p keys
ssh-keygen -b 4096 -t rsa -f keys/sq-proj1-ssh -N "" -C "sq-proj1-ssh"
chmod 600 keys/sq-proj1-ssh
echo ""

## Adding Public Key to git hub
gh ssh-key add keys/sq-proj1-ssh.pub -t sq-porj1-ssh
# Checking if last command was successfull and outputing the relevant statement.
if [ $? -eq 0 ]; then
    echo ""
    echo "Successfully added Public Key to GitHub."
    echo ""
else 
    echo ""
    echo "Failed to inject your Public Key to GitHub."
    echo "You might not have 'gh' installed or, the key is already there."
    echo "If the latter isn't the case, please add manually the Public Key to your GitHub account."
    echo ""
fi

#### Local configation ####

## Terrform apply
echo "Creating infrastructure on AWS, this might take some time..."
cd terraform
terraform init # >/dev/null 2>&1  ## This has lots of outputs, redirecting stdout to null and leaving stderr to the screen.
terraform apply -auto-approve # >/dev/null 2>&1 ## This has lots of outputs, redirecting stdout to null and leaving stderr to the screen.
cd ..
echo "Infrastrucure is up, configuring servers ..."
echo ""


echo "Adding SSH Key fingerprints ..." 

# Collecting ec2 ips from hosts file
J_CONTROLLER=$(cat ansible/hosts | sed '2!d')
PROD1=$(cat ansible/hosts | sed '4!d')
PROD2=$(cat ansible/hosts | sed '5!d')
HOSTS=($J_CONTROLLER $PROD1 $PROD2)

## Scan ssh key fingerprint from all EC2 intsance 
## into the ~/.ssh/known_hosts files of the ansible controller.
# Looping through the EC2 instances and scanning their fingerprints,
# and adding them to known_hosts file in the ansible client.
for host in "${HOSTS[@]}"
do  
    ssh-keyscan -t rsa $host >> ~/.ssh/known_hosts
done

#### Hosts configuration ####

## Running ansible commands in logical (correct) order.
echo "Running ansible tasks ..."
## Docker
ansible-playbook -i ansible/hosts --key-file keys/sq-proj1-ssh -u ubuntu ansible/playbooks/docker_install.yaml

## Insatalling Java & AwsCLI on Prod1 and Prod2
ansible-playbook -i ansible/hosts --key-file keys/sq-proj1-ssh -u ubuntu ansible/playbooks/production_machines.yaml

## Running the Jenkins CasC palybook and injecting variable to it.
ansible-playbook -i ansible/hosts --key-file keys/sq-proj1-ssh -u ubuntu \
--extra-vars "CONTROLLER_IP=${J_CONTROLLER}" \
--extra-vars "awsID=${awsID}" \
--extra-vars "awsSECRET=${awsSECRET}" \
--extra-vars "gitEmail=${gitEmail}" \
ansible/playbooks/custom_jenkins_install.yaml


LOAD_BALANCER_IP=$(tail -1 ansible/loadbalancer)
echo """
Infrastructure and servers are up and configured.
head over to http://${J_CONTROLLER}:8080 and view the Jenkins installation and its jobs.
Oce you ran them, you can also head to the Load-Balancer's IP to checkout the service : http://${LOAD_BALANCER_IP}/
To tear everything down simply run './stopme.sh' and wait for the proccess to finish.
"""