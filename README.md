# Redhat Pacemaker active-passive HA cluster on AWS (RHEL10 - 2 node cluster - LAB environment)
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
    
3. Run bellow given terraform commands \
    terraform init \
    terraform plan \
    terraform apply -auto-approve 
    
4. If we need more than 2 cluster node use the below give terraform apply command (Suppose for 3  cluster nodes)
   
    terraform apply **-var=server_count=3** -auto-approve 
    
6. If getting bellow error, just re-run "terraform apply -auto-approve"
   
    <img width="1170" height="498" alt="image" src="https://github.com/user-attachments/assets/c883c46f-463c-431d-8389-f59bb6a9b16f" />
	
8. Access the cluster node
   
   	chmod 600 id_rsa \
	ssh -o StrictHostKeyChecking=no -i id_rsa ec2-user@<Public_IP_of_EC2_Instance> 
	
10. Run pcs status to check the cluster status
    <img width="1224" height="744" alt="image" src="https://github.com/user-attachments/assets/cdbb4532-b013-4ed1-9536-3ff09f0715d0" />

11. Access the website from the nodes \
   	curl http://192.168.100.100

==============================================================
