## Each Node config
/usr/bin/dnf install -y pacemaker corosync pcs fence-agents-aws resource-agents-cloud resource-agents
/usr/bin/systemctl enable pcsd --now
/usr/bin/echo R3dh@tPa55 | /usr/bin/passwd hacluster --stdin
ServerName=$(hostname)
ServerCount=$(cat /etc/hosts|grep server|wc -l)

## Update AWS Key in each nodes
  /usr/bin/aws configure set region us-east-1
  /usr/bin/aws configure set aws_access_key_id $(/usr/bin/head -n 1  /var/tmp/aASKey |cut -d "=" -f2)
  aws configure set aws_secret_access_key $(/usr/bin/tail -n 1  /var/tmp/aASKey |cut -d "=" -f2)

if [ "$ServerName" == "server00" ]; then
    sleep 60
    for ((i=0; i<ServerCount; i++)); do
      /usr/sbin/pcs host auth server0$i -u hacluster -p R3dh@tPa55
    done
  /usr/sbin/pcs cluster setup webserver --start server00 server01
  /usr/sbin/pcs cluster enable --all
  /usr/sbin/pcs property set stonith-enabled=true
  /usr/sbin/pcs property set no-quorum-policy=ignore
  /usr/bin/sed -z 's/\n/\;/g; s/..$//' /var/tmp/instances| sed 's/ //g' | sed 's/.$//' > /var/tmp/InstanceID
  /usr/bin/sed -z 's/\n//g; s/..$//' aASKey

## Resource configuration for Stonith
  /usr/sbin/pcs stonith create clusterfence fence_aws pcmk_reboot_action=reboot pcmk_host_map=$(cat /var/tmp/InstanceID) $(cat /var/tmp/aASKey)

## Resource configuration for VIP
  /usr/sbin/pcs  resource create vip_aws ocf:heartbeat:aws-vpc-move-ip \
  ip="192.168.100.100" \
  routing_table="$(cat /var/tmp/Route_ID)" \
  interface="ens5" op monitor interval="10s"
  
## Resurce group for Webserver application
  /usr/sbin/pcs resource group add Webserver vip_aws
fi