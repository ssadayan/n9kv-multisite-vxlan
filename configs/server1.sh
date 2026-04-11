#!/bin/bash
# Server1 - Site 1, Leaf1 - VLAN 10 - 192.168.10.1/24
ip link add link eth1 name eth1.10 type vlan id 10
ip link set dev eth1.10 up
ip addr add 192.168.10.1/24 dev eth1.10
ip route add 192.168.20.0/24 via 192.168.10.254
