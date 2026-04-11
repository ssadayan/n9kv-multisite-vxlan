#!/bin/bash
# Server3 - Site 2, Leaf3 - VLAN 10 - 192.168.10.3/24
ip link add link eth1 name eth1.10 type vlan id 10
ip link set dev eth1.10 up
ip addr add 192.168.10.3/24 dev eth1.10
ip route add 192.168.20.0/24 via 192.168.10.254
