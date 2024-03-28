#!/bin/bash
iptables -I DOCKER-USER -i eth0,wlan0 -j DROP
iptables -I DOCKER-USER -j LOG --log-prefix "DOCKER-DROP: "
iptables -I DOCKER-USER -i eth0,wlan0 -p tcp -s <TAILSCALE_IP_RANGE> --sport 443 --dport 443 -j ACCEPT
iptables -I DOCKER-USER -i eth0,wlan0 -p tcp -s <LOCAL_NETWORK_IP_RANGE> --sport 443 --dport 443 -j ACCEPT
iptables -I DOCKER-USER -m mac --mac-source <MAC_ADDRESSES_TO_BLOCK> -j DROP
iptables -I INPUT -m mac --mac-source <MAC_ADDRESSES_TO_BLOCK> -j DROP



