## Each Node config
/usr/bin/dnf install -y pacemaker corosync pcs fence-agents-aws resource-agents-cloud resource-agents
/usr/bin/systemctl enable pcsd --now
/usr/bin/echo R3dh@tPa55 | /usr/bin/passwd hacluster --stdin
ServerName=$(hostname)
ServerCount=$(cat /etc/hosts|grep server|wc -l)

## Update AWS Key in each nodes
  /usr/bin/aws configure set region $(/usr/bin/awk 'NR==1' /var/tmp/aASKey |cut -d "=" -f2)
  /usr/bin/aws configure set aws_access_key_id $(/usr/bin/awk 'NR==2' /var/tmp/aASKey |cut -d "=" -f2)
  /usr/bin/aws configure set aws_secret_access_key $(/usr/bin/awk 'NR==3' /var/tmp/aASKey |cut -d "=" -f2)

## Apache installation and Filesystem configuration
  /usr/bin/dnf install -y httpd
  /usr/bin/cat <<-END > /etc/httpd/conf.d/status.conf
  <Location /server-status>
    SetHandler server-status
    Require local
  </Location>
END
## Cluster configuration
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

## Cluster resource configuration for Stonith
  /usr/sbin/pcs stonith create clusterfence fence_aws pcmk_reboot_action=reboot pcmk_host_map=$(cat /var/tmp/InstanceID) $(cat /var/tmp/aASKey)

## Cluster resource configuration for VIP
  /usr/sbin/pcs  resource create VIP ocf:heartbeat:aws-vpc-move-ip \
  ip="192.168.100.100" \
  routing_table="$(cat /var/tmp/Route_ID)" \
  interface="ens5" op monitor interval="10s"

## Creating cluster filesystem
  Disk=$(/usr/sbin/fdisk -l|grep "10 Gi" | /usr/bin/awk '{print substr($2, 1, length($2)-1)}')
  /usr/sbin/pvcreate $Disk
  /usr/sbin/vgcreate --setautoactivation n appvg $Disk
  /usr/sbin/lvcreate -L 2G -n /dev/appvg/applv
  /usr/sbin/mkfs.xfs /dev/appvg/applv
  /usr/bin/systemctl disable lvm2-monitor
  /usr/sbin/lvmdevices --adddev $Disk

  /usr/bin/mount -t xfs /dev/appvg/applv /mnt/
  /usr/bin/echo "<h1>Welcome to Redhat Pacemaker Cluster on AWS</h1>" > /mnt/index.html
  /usr/bin/umount /mnt/
  /usr/sbin/vgchange -an appvg
  /usr/sbin/restorecon -Rv /var/www/html
  /bin/systemctl reload httpd.service > /dev/null 2>/dev/null || true
## Cluster resource configuration for Filesystem
  pcs resource create LVM ocf:heartbeat:LVM-activate vgname="appvg" vg_access_mode="system_id"
  pcs resource create FileSystem ocf:heartbeat:Filesystem device="/dev/appvg/applv" directory="/var/www/html" fstype="xfs"

## Cluster resource configuration for Apache service
  pcs resource create Apache ocf:heartbeat:apache configfile="/etc/httpd/conf/httpd.conf" 

## Resurce group for Webserver application
  /usr/sbin/pcs resource group add Webserver LVM FileSystem Apache VIP 
else
sleep 120
lvmdevices --adddev $(lvmdevices|awk '{print $2}')
/usr/sbin/restorecon -Rv /var/www/html
/bin/systemctl reload httpd.service > /dev/null 2>/dev/null || true
fi

