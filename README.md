# manage-iptables.sh

A script to flush all rules from Iptables and add a new custom setup examples in the script support

- DNAT
- SNAT
- Blocking (Dropping of packets)
- Port forwarding
- Opening ports (such as port 22)  
- Outbound nat (Masquerade)
- TCP/UDP/ICMP rules
- Established & Related connection tracking
 
I use this script to manage Linux firewalls that pass traffic to an internal network but it can be used for a single server/host etc.

This script does not restart Iptables when applying the update it uses iptables-save.
