#!/bin/bash
# Just Testing
/usr/bin/touch /tmp/Boot
Host=$(uname -n)
if [ $Host == "server00" ];then
/usr/bin/touch /tmp/Server00
else
/usr/bin/touch /tmp/Server01
fi