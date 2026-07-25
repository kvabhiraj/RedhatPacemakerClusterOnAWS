/usr/bin/dnf install -y pacemaker corosync pcs fence-agents-all
/usr/bin/systemctl enable pcsd --now
/usr/bin/echo R3dh@tPa55 | /usr/bin/passwd hacluster --stdin
ServerName=$(hostname)
ServerCount=$(cat /etc/hosts|grep server|wc -l)
if [ "$ServerName" == "server00" ]; then
    sleep 120
    for ((i=0; i<ServerCount; i++)); do
      /usr/sbin/pcs host auth server0$i -u hacluster -p R3dh@tPa55
    done
  /usr/sbin/pcs cluster setup webserver --start server00 server01
  /usr/sbin/pcs cluster enable --all
  /usr/sbin/pcs property set stonith-enabled=true
  /usr/sbin/pcs property set no-quorum-policy=ignore
fi