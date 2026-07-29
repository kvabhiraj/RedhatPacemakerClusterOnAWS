/usr/bin/dnf install -y pacemaker corosync pcs fence-agents-aws resource-agents-cloud resource-agents
/usr/bin/systemctl enable pcsd --now
/usr/bin/echo R3dh@tPa55 | /usr/bin/passwd hacluster --stdin
ServerName=$(hostname)
ServerCount=$(cat /etc/hosts|grep server|wc -l)
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
  /usr/sbin/pcs stonith create clusterfence fence_aws region=us-east-1 pcmk_reboot_action=reboot pcmk_host_map=$(cat /var/tmp/InstanceID) $(cat /var/tmp/aASKey)
fi