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
terraform init >/dev/null 2>&1  ## This has lots of outputs, redirecting stdout to null and leaving stderr to the screen.
terraform apply -auto-approve >/dev/null 2>&1 ## This has lots of outputs, redirecting stdout to null and leaving stderr to the screen.
cd ..
echo "Infrastrucure is up, configuring servers ..."
echo ""


echo "Adding SSH Key fingerprints ..." 

# Collecting ec2 ips from hosts file
J_CONTROLLER=$(cat ansible/hosts | sed '2!d')
J_AGENT=$(cat ansible/hosts | sed '4!d')
PROD1=$(cat ansible/hosts | sed '6!d')
PROD2=$(cat ansible/hosts | sed '8!d')
HOSTS=($J_CONTROLLER $J_AGENT $PROD1 $PROD2)

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

## Jenkins (Moved to custom_jenkins_install)
# ansible-playbook -i ansible/hosts --key-file keys/sq-proj1-ssh -u ubuntu ansible/playbooks/jenkins_install.yaml

## Java on agent
ansible-playbook -i ansible/hosts --key-file keys/sq-proj1-ssh -u ubuntu ansible/playbooks/java_11_install.yaml

## awscli on agent
ansible-playbook -i ansible/hosts --key-file keys/sq-proj1-ssh -u ubuntu ansible/playbooks/z-aws-cli.yaml

## SSH Fingerprint (agent)
ansible-playbook -i ansible/hosts --key-file keys/sq-proj1-ssh -u ubuntu ansible/playbooks/ssh_fingerprint_agent.yaml

## Running the Jenkins CasC palybook and injecting variable to it.
ansible-playbook -i ansible/hosts --key-file keys/sq-proj1-ssh -u ubuntu \
--extra-vars "J_Agent=${J_AGENT}" \
--extra-vars "awsID=${awsID}" \
--extra-vars "awsSECRET=${awsSECRET}" \
ansible/playbooks/custom_jenkins_install.yaml



echo """
Infrastructure and servers are up and configured.
head over to http:/${J_CONTROLLER}:8080 and view the Jenkins installation and its jobs.

To tear everything down simply run './stopme.sh' and wait for the proccess to finish.
"""