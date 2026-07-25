#!/bin/bash
# Enable password authentication
/usr/bin/sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/50-cloud-init.conf
/usr/bin/sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
/usr/bin/sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
/usr/bin/echo "ClientAliveInterval 600" | /usr/bin/tee -a /etc/ssh/sshd_config
/usr/bin/echo "ClientAliveCountMax 10" | /usr/bin/tee -a /etc/ssh/sshd_config
/usr/bin/systemctl restart sshd


# Set user passwords
/usr/sbin/useradd abhirajkv 
/usr/bin/echo "Passwd_09"|passwd abhirajkv --stdin
/usr/bin/echo "Passwd_09"|passwd ec2-user --stdin
/usr/bin/echo "Passwd_09"|passwd root --stdin
/usr/bin/echo "abhirajkv  ALL=(ALL)     NOPASSWD: ALL" > /etc/sudoers.d/abhirajkv


# Enable epel repository
/usr/bin/dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm -y
/usr/bin/dnf clean all
/usr/bin/dnf repolist

# Change hostname
/usr/bin/sed -i 's/preserve_hostname: false/preserve_hostname: true/g' /etc/cloud/cloud.cfg
HOSTNAME=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/tags/instance/Name);/usr/bin/hostnamectl --static set-hostname $HOSTNAME

# Network Static IP configuration
DEV=$(/usr/bin/nmcli con show|egrep -v "loopback|DEVICE"|awk '{print $4}')
IP=$(/usr/sbin/ip a|grep -i inet|grep ens5|awk '{print $2}')
GW=$(/usr/bin/netstat -nr| awk '{print $2}' |egrep -v "IP|Gateway|0.0.0.0")
DNS=$(/usr/bin/cat /etc/resolv.conf |grep nameserver|awk '{print $2}')

/usr/bin/nmcli connection modify "cloud-init ens5" connection.id "ens5"
/usr/bin/nmcli connection modify ens5 ipv6.method disabled
/usr/bin/nmcli connection modify ens5 ipv6.method disabled
/usr/bin/nmcli connection down "cloud-init ens5";/usr/bin/nmcli connection up "ens5"

/usr/bin/nmcli con mod "$DEV" ipv4.addresses "$IP" ipv4.method manual
/usr/bin/nmcli con mod "$DEV" ipv4.gateway "$GW"
/usr/bin/nmcli con mod "$DEV" ipv4.dns "$DNS"
/usr/bin/nmcli con up "$DEV" 
