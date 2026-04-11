#!/bin/bash
# Server4 - Site 2, Leaf4 - VLAN 20 - 192.168.20.4/24
ip link add link eth1 name eth1.20 type vlan id 20
ip link set dev eth1.20 up
ip addr add 192.168.20.4/24 dev eth1.20
ip route add 192.168.10.0/24 via 192.168.20.254
