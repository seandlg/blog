#!/bin/bash

########################################################################################
# Step 1:
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
echo "1) Identifying physcial interfaces..."
interfaces=`iw dev | grep "phy#[0-9]" | awk 'BEGIN { ORS=" " } { print $0 }'`
IFS=' '
read -ra PHYS <<< "$interfaces"
for elem in "${PHYS[@]}"; do
	echo "Found interface $elem"
done
echo ""

echo "Please select the upstream interface"
read if_up

echo "Testing upstream connection"
ifname_if_up=`iw dev | grep "$if_up" -C 1 | grep -o "wl[a-z0-9]*"`
curldata=`curl -s ifconfig.co --interface "$ifname_if_up" | xargs`
if [[ -z `echo "$curldata" | grep "[0-9\.]*"` ]]; then
	echo "No internet connection on upstream"
	exit 0
else
	echo "Connected with IP $curldata"
fi
echo "DONE"

########################################################################################
# Step 2: 
echo "2) Configuring the AP"
echo "Please select the physical interface to host the AP on"
read in_ap
ifname_if_ap=`iw dev | grep "$in_ap" -C 1 | grep -o "wl[a-z0-9]*"`

ipaddresses="10.42.42.1/24"
echo "Adding IP-Addresses $ipaddresses to Interface $ifname_if_ap"
ip addr del $ipadresses dev $ifname_if_ap
ip addr add $ipadresses dev $ifname_if_ap
echo "DONE"

########################################################################################
# Step 3:
echo "3) DHCP & DNS"
echo "Setting up DHCP & DNS server at $ipaddresses"
killall -9 dnsmasq
dnsmasq -C dnsmasq.conf -d 
echo "DONE"

########################################################################################
# Step 4:
echo "Setting iptable rules"
local_addr=`ip addr | grep $ifname_if_up | grep -P -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1`
iptables -t nat -F
iptables --table nat --append POSTROUTING --out-interface $ifname_if_up -j SNAT --to $local_addr
echo 1 > /proc/sys/net/ipv4/ip_forward
########################################################################################
# Step 5:
echo "5) Setup complete. Spawning AP."
hostapd hostapd.conf
