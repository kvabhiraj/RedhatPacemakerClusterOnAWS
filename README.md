		Redhat Pacemaker HA Cluster on AWS (RHEL9 - 2 node)
Pre-requisites
==============================================================
01. Install and configure AWS CLI in your system (Linux / Mac) \
	a. Install AWS CLI \
		https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html \
	b. Authenticating using IAM user credentials for the AWS CLI \
		https://docs.aws.amazon.com/cli/v1/userguide/cli-authentication-user.html \
02. Install and configure GIT \
	a.  Install GIT \
		https://github.com/git-guides/install-git \
	b. Setup GIT \
		https://docs.github.com/en/get-started/git-basics/set-up-git \
03. Install and configure terraform \
	a. Install Terraform \
		https://developer.hashicorp.com/terraform/install \


Clone the GIT repository 
==============================================================
git clone -b main https://github.com/kvabhiraj/RedhatPacemakerClusterOnAWS.git \
cd RedhatPacemakerClusterOnAWS \


Initiate IAC to deploy EC2 instances
==============================================================
terraform init \
terraform plan \
terraform apply -auto-approve \

To be continued
==============================================================
