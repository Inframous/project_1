# SQ-Labs Project1
## AWS, Jenkins, Docker, Linux.

With this project, we will: 
- Launch aws infrastructure using Terraform.
- Install and configure EC2 instances using Ansible.
- Use Docker to run an example service.
- Use Jenkins to implement CI/CD piplines to test and deploy the service. 

## Prerequisites


- AWS Credentials (Access Key ID + Secret Access Key).
- A computer with Terraform and Ansible installed.
- Terraform, comfigured with your aws-credentials (outside of the scope of this document).
- (Optional) - Having 'gh' installed and logged in, will grant the scipt the option to upload the ssh keys to your GitHub account. 

## Installation:
- Clone the repo: `$ git clone https://github.com/Inframous/project_1.git`
- Go into the infrastructure/terraform folder and run: 
```
$ ./runme.sh
```

This script will orchestrate this whole operation.
It will first grab your AWS Credentials from ~/.aws/credenatials,
then it will create Private and Public SSH keys to be used with Terraform and also
add them to your git hub account assuming you're logged in via 'gh'.
Then it will run 'terraform init' and 'terraform apply -auto-approve' to start your infrastrcutre.
It'll continue running Ansible Playbooks by order installing and configuring all that is neccesary.
(for details see below)

Once the script is done, it'll return a URL.
Point your browser to said URL, and log on to the now available Jenkins-Controller.


## Terraform

Terraform will deploy 3 EC2 instances within their own VPC, 2 Subnets, A Security Group, inbound and outbound rules (All Traffic), and dedicated Subnet along with the necessary ssh keys, it will create a S3 Bucket, a DynamoDB table and finally, it will create an Application Load Balancer.
##### The EC2s are named as follows:
- Jenkins-Controller
- Prod1
- Prod2


Private IPs were hardcoded to all EC2 instances for easy configuration within Jenkins.

Once the ‘terraform apply’ process is done, terraform will retrieve the Public IP of all EC2 instances and create the Ansible hosts file with the corresponding names for each EC2.
(This will come handy in the next step - Ansible.)

The Terraform files are divided by subjects for easier use (Network,DynamoDB, S3 etc .. )

## Ansible

Once the infrastructure is ready, we’ll run the following Ansible Playbooks:
- docker_install.yaml → Will install Docker on all instances.
- java_install.yaml 
- custom_jenkins_install.yaml → Will pull a git repo, build and deploy a Jenkins Docker Container, 
that was pre configured using the Configuration as Code plugin on the EC2 named Jenkins-Controller.


## Jenkins
The Jenkins installation was built and configured using the CasC repo built for this project.
repo: <url>https://github.com/Inframous/sq-jenkins-casc</url>
There you'll see the Dockerfile with the missing credentials along with a casc.yaml and plugins.txt.
The above are used to create the Jenkins-casc container.
It is preconfigured with an Agent, an Admin and Normal user accounts with different permissions, 
credentials for AWS, GitHub and the Agent and even the jobs themselves (minus a few glitches).


## The Jenkins Jobs

### 1. Test-Aws:
This job will use the Jenkins Agent to download the code from the GitHub repo,
build a container image and test the code using the unittest python library.
It will also log the test into report.csv and upload it to an s3 bucket.
Once the results are returned an environment variable will be set to SUCCESS or FAIL.
If the test fails the job will stop and report.
However if the test succeeds the job will trigger another job → AWS-Deploy.


### 2. Deploy-Aws:
This pipeline will deploy to one, the other, or both Productions Server(s).
(pending on the value of the KEY variable within the job)
First, it will connect to the server(s), stop and remove the possible running container and image, 
then it will download, build and deploy the app.
Once the deployment is done, the job will download the latest test results from the previous job, 
parse the last line and upload it as an new item in the DynamoDB table.
