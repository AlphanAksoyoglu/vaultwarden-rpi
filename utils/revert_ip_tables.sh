#!/bin/bash
iptables -F DOCKER-USER
iptables -A DOCKER-USER -j RETURN
iptables -D INPUT -m mac --mac-source <MAC_ADDRESSES_TO_BLOCK> -j DROP


