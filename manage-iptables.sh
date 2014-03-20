#!/bin/bash
# ./manage-iptables.sh to run the script
# Flush all current configuration rules
#
# *** WARNING ****
# This script by default allows SSH (port 22) in and ICMP (ping) in to any interface 
# ****************
#
# Check we are being run as root
#
if [ "$(id -u)" != "0" ]; then
   echo "$0 must be run as root" 1>&2
   exit 1
fi
#
# Attempt to determine linux version
#
PLATFORM=$(uname -s)
if [[ "$PLATFORM" == "Linux" ]]; then
	OS=$(lsb_release -a 2> /dev/null | grep Distributor | awk '{ print $3 }')
	if [[ "$OS" == "" ]]; then
		OS=$(cat /etc/{*issue*,*release*} | grep -m 1 -E '(CentOS|Ubuntu|Fedora)' | awk '{ print $1 }')
		if [[ "$OS" == "" ]]; then
			echo "Cannot reliably determine OS type, exiting!"
			exit 1
		fi
	fi
else
	echo "Platform not Linux, \"$PLATFORM\" not supported exiting!"
	exit 1
fi 
#
# Flush all existing rules
#
 echo -n "Flushing tables..."
 iptables -F
 iptables -t nat -F
 iptables -t mangle -F
 printf "%-10s[ OK ]\n"
#
# Set default policies for INPUT, FORWARD and OUTPUT chains
#
 echo -n "Setting default DROP rules..."
 iptables -P INPUT DROP
 iptables -P FORWARD DROP
 iptables -P OUTPUT ACCEPT
 printf "%-10s[ OK ]\n"
#
# Set access for localhost
#
 echo -n "Setting access for localhost..."
 iptables -A INPUT -i lo -j ACCEPT
 iptables -A INPUT -p icmp -j ACCEPT
 printf "%-10s[ OK ]\n"
#
# Accept packets belonging to established and related connections
#
 echo -n "Allowing ESTABLISHED and RELATED sessions..."
 iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
 iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
 printf "%-10s[ OK ]\n"
#
# Accept inbound connections to host
#
 echo -n "Adding access to Host services..."
# NTP Rules
# iptables -A INPUT -i ppp0 -p udp -m state --state NEW -m udp --dport 123 -j ACCEPT
# SNMP Rules
# iptables -A INPUT -i ppp0 -p udp -m state --state NEW -m udp --dport 161 -j ACCEPT
 printf "%-10s[ OK ]\n"
#
# Allow Management SSH 
#
 echo -n "Allowing MANAGEMENT connections..."
# Default ***all interfaces*** for safety so you don't lock yourself out!
 iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
# iptables -A INPUT -s xxx.xxx.xxx.xxx/xx -d xxx.xxx.xxx.xxx/32 -i eth0 -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
 printf "%-10s[ OK ]\n"
#
# Outgoing NAT
#
# Change source of a internal IP to a different external IP assuming you have more than 1 external IP routed to interface ppp0
 echo -n "OUTGOING POSTROUTING rules..."
# iptables -t nat -A POSTROUTING -s 192.168.xxx.xxx/xx -o ppp0 -j SNAT --to-source xxx.xxx.xxx.xxx 
 printf "%-10s[ OK ]\n"
#
# Mangle table for dropping packets as they first arrive
#
 echo -n "Adding MANGLE rules..."
# Special mangle (first table) rule for offending IP. 
# Example to drop packets to a mail server (SMTP)
# iptables -t mangle -A PREROUTING -p tcp -i ppp0 -s xxx.xxx.xxx.xxx -d xxx.xxx.xxx.xxx --dport 25 -j DROP
# Example to drop packets to a DNS server from a particular offending IP
# iptables -t mangle -A PREROUTING -p udp -i ppp0 -s xxx.xxx.xxx.xxx -d xxx.xxx.xxx.xxx --dport 53 -j DROP
 printf "%-10s[ OK ]\n"
#
# Prerouting rules - If you want to modify packets before they hit the routing table (As you would for port forwarding)
# Source and Destination NAT for incoming or outgoing connections
# Note: that you can also modify the port
#
 echo -n "Adding PREROUTING rules..."
# NAT internal IP to External IP (ports stay the same)
# iptables -t nat -A PREROUTING -s 192.168.xxx.xxx -p tcp -j SNAT --to-source xxx.xxx.xxx.xxx
# NAT External IP to Internal IP changing the destination port
# iptables -t nat -A PREROUTING -p tcp -i ppp0 -d xxx.xxx.xxx.xxx --dport 443 -j DNAT --to 192.168.xxx.xxx:22
# Nat External IP to Internal IP keeping the original destination port
# iptables -t nat -A PREROUTING -p tcp -i ppp0 -d xxxx.xxx.xxx.xxx --dport 80 -j DNAT --to 192.168.xxx.xxx
 printf "%-10s[ OK ]\n"
#
# Postrouting rules
# Modifying packets once they have been routed, eg changing the source address
#
 echo -n "Adding POSTROUTING rules..."
# NAT source address for incomming connection to internal IP (You might want to do this if you destination
# host does not have a default gateway or a different default gateway to where your packet originated)
# iptables -t nat -A POSTROUTING -p tcp -d 192.168.xxx.xxx --dport 25 -j MASQUERADE
# Modify only packets with a specific source, destination and port
# iptables -t nat -A POSTROUTING -p tcp -s xxx.xxx.xxx.xxx -d 192.168.xxx.xxx --dport 8080 -j MASQUERADE
# Modify a range of ports
# iptables -t nat -A POSTROUTING -p tcp -d 192.168.xxx.xxx --dport 50110:50210 -j MASQUERADE
 printf "%-10s[ OK ]\n"
#
# Add Rules to FORWARD Chain
# All rules that traverse the firewall/router (POSTROUTING, PREROUTING) must have a corresponding FORWARD rule
# A rule must be added to allow outbound connections
#
 echo -n "Adding FORWARD rules..."
# iptables -A FORWARD -i tun0 -j ACCEPT
# iptables -A FORWARD -i eth0 -s 192.168.xxx.xxx -d 0.0.0.0/0 -j DROP
# Rule to allow outbound connections incoming port eth0, outgoing port ppp0
# iptables -A FORWARD -i eth0 -o ppp0 -d 0.0.0.0/0 -j ACCEPT
# A less strict outbound rule, you can make these as strict or less strick as you feel secure (remember the more specific the better)
# iptables -A FORWARD -i eth0 -d 0.0.0.0/0 -j ACCEPT
# Exmaples for incoming PREROUTING/POSTROUTING rules
# iptables -A FORWARD -p tcp -m tcp --dport 80 -d 192.168.xxx.xxx -j ACCEPT
# iptables -A FORWARD -p tcp -m tcp --dport 50110:50210 -d 192.168.xxx.xxx -j ACCEPT
 printf "%-10s[ OK ]\n"
# Save settings without restarting Iptables
#
if [[ "$OS" == "Ubuntu" ]]; then
	iptables-save > /etc/iptables.rules
else
	service iptables save
fi
#
# List rules
#
#/sbin/service iptables restart
# 
# Uncomment the below to print firewall rule status once updated
# iptables -L -vn && iptables -t nat -L -nv
#