/usr/bin/dnf install -y pacemaker corosync pcs fence-agents-all
/usr/bin/systemctl enable pcsd --now
/usr/bin/echo R3dh@tPa55 |/usr/bin/passed hacluster --stdin
ServerName=$(hostname)
if [ "$ServerName" == "server00" ]; then
  /usr/sbin/pcs cluster auth server00 server01 -u hacluster -p R3dh@tPa55 --force
  /usr/sbin/pcs cluster setup --name webserver server00 server01
  /usr/sbin/pcs cluster start --all
  /usr/sbin/pcs property set stonith-enabled=false
  /usr/bin/pcs property set no-quorum-policy=ignore
fi