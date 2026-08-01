		Redhat Pacemaker HA Cluster on AWS (RHEL9 two-node cluster LAB environment)
Pre-requisites
==============================================================
01. Install and configure AWS CLI in your system (Linux / Mac) \
	a. Install AWS CLI \
		https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html \
	b. Authenticating using IAM user credentials for the AWS CLI \
		https://docs.aws.amazon.com/cli/v1/userguide/cli-authentication-user.html 
02. Install and configure GIT \
	a.  Install GIT \
		https://github.com/git-guides/install-git \
	b. Setup GIT \
		https://docs.github.com/en/get-started/git-basics/set-up-git 
03. Install and configure terraform \
	a. Install Terraform \
		https://developer.hashicorp.com/terraform/install 


Clone the GIT repository 
==============================================================

01. Redhat pacemaker high-availability cluster (Active-passive) # Baseline \
		git clone -b main https://github.com/kvabhiraj/RedhatPacemakerClusterOnAWS.git
02. Redhat pacemaker high-availability cluster (Active-passive) # Web server using httpd \
		git clone -b WebServer https://github.com/kvabhiraj/RedhatPacemakerClusterOnAWS.git 
 

Initiate IAC to deploy EC2 instances
==============================================================
01. Update AWS Access Key & Secret Access Key in file aASKey \
    cd RedhatPacemakerClusterOnAWS \
    vi aASKey
02. Run bellow given terraform commands \
    terraform init \
    terraform plan \
    terraform apply -auto-approve \
03. If getting bellow error just re-run "terraform apply -auto-approve" \
    Error: file provisioner error
│ 
│   with null_resource.copy_files["1"],  \
│   on ec2_instance.tf line 82, in resource "null_resource" "copy_files":  \
│   82:   provisioner "file" {
│ 
│ host for provisioner cannot be empty
╵
╷
│ Error: file provisioner error
│ 
│   with null_resource.copy_files["0"], 
│   on ec2_instance.tf line 82, in resource "null_resource" "copy_files": \
│   82:   provisioner "file" { \
│ 
│ host for provisioner cannot be empty



To be continued
==============================================================
