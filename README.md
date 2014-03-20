manage-iptables.sh
==================

A script to flush all rules from Iptables and add a new custom setup basic examples in the script support

## Examples:

- DNAT
- SNAT
- Blocking/Dropping
- Port forwarding
- Inbound ports (such as port 22)  
- Outbound nat (Masquerade)
- TCP/UDP/ICMP rules
- Established & Related connection tracking
 
Use this script to setup intial Linux Iptables routers/firewalls that either pass traffic to an internal network or initially configure a server/host firewall.

## Ubuntu users

Ubuntu users will need to add the iptables script to /etc/network/if-pre-up.d/ & /etc/network/if-post-down.d/

Linux routing requirements
--------------------------

### /proc/sys/net/ipv4/ip_forward must be set to 1 

Linux will not forward packets through its interfaces unless this option is set to 1. Be sure to make it **persistent**. 

#### Check if its enabled

`cat /proc/sys/net/ipv4/ip_forward`

or

`sysctl net.ipv4.ip_forward`

#### Enable without a reboot

`echo 1 > /proc/sys/net/ipv4/ip_forward`

or 

`sysctl -w net.ipv4.ip_forward=1`

#### Persistently enable 

Edit /etc/sysctl.conf and set; 

net.ipv4.ip_forward = 1