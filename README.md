# n9kv-multisite-vxlan

A containerlab lab demonstrating **Multi-Site VXLAN/EVPN** across two data center sites using Cisco Nexus 9300v (NX-OS 9.3.16).

## Topology

Spineless design — BGWs act as both route reflectors and border gateways. Full-mesh DCI between all BGWs across sites.

```
  ┌──────────────────────── Site 1 (AS 65001) ────────────────────────────┐
  │                                                                        │
  │   s1-bgw1 (lo0:10.1.0.21, lo1:10.1.0.121, lo100:10.1.100.21)         │
  │   s1-bgw2 (lo0:10.1.0.22, lo1:10.1.0.122, lo100:10.1.100.21) anycast │
  │       |  \________                                                     │
  │       |           \                                                    │
  │   s1-leaf1 (lo0:10.1.0.11, lo1/VTEP:10.1.0.111)                      │
  │   s1-leaf2 (lo0:10.1.0.12, lo1/VTEP:10.1.0.112)                      │
  │       |                 |                                              │
  │  srv1(192.168.10.1)  srv2(192.168.10.2)                               │
  │  srv5(192.168.10.5)                                                    │
  │                                                                        │
  └────────────────────── DCI (full mesh) ────────────────────────────────┘
                                 |
  ┌──────────────────────── Site 2 (AS 65002) ────────────────────────────┐
  │                                                                        │
  │   s2-bgw1 (lo0:10.2.0.21, lo1:10.2.0.121, lo100:10.2.100.21)         │
  │   s2-bgw2 (lo0:10.2.0.22, lo1:10.2.0.122, lo100:10.2.100.21) anycast │
  │       |  \________                                                     │
  │       |           \                                                    │
  │   s2-leaf1 (lo0:10.2.0.11, lo1/VTEP:10.2.0.111)                      │
  │   s2-leaf2 (lo0:10.2.0.12, lo1/VTEP:10.2.0.112)                      │
  │       |                 |                                              │
  │  srv3(192.168.10.3)  srv4(192.168.10.4)                               │
  │  srv6(192.168.10.6)                                                    │
  │                                                                        │
  └────────────────────────────────────────────────────────────────────────┘
```

## Nodes

| Node | Role | AS | lo0 (BGP RID) | lo1 (VTEP) | lo100 (Multisite BGW) |
|------|------|----|---------------|------------|----------------------|
| s1-bgw1 | BGW + RR | 65001 | 10.1.0.21/32 | 10.1.0.121/32 | 10.1.100.21/32 |
| s1-bgw2 | BGW + RR | 65001 | 10.1.0.22/32 | 10.1.0.122/32 | 10.1.100.21/32 (anycast) |
| s1-leaf1 | Leaf | 65001 | 10.1.0.11/32 | 10.1.0.111/32 | — |
| s1-leaf2 | Leaf | 65001 | 10.1.0.12/32 | 10.1.0.112/32 | — |
| s2-bgw1 | BGW + RR | 65002 | 10.2.0.21/32 | 10.2.0.121/32 | 10.2.100.21/32 |
| s2-bgw2 | BGW + RR | 65002 | 10.2.0.22/32 | 10.2.0.122/32 | 10.2.100.21/32 (anycast) |
| s2-leaf1 | Leaf | 65002 | 10.2.0.11/32 | 10.2.0.111/32 | — |
| s2-leaf2 | Leaf | 65002 | 10.2.0.12/32 | 10.2.0.112/32 | — |

## Underlay Links

### Site 1 (OSPF UNDERLAY, area 0.0.0.0, P2P, MTU 9150)
| Link | Subnet | Node A | Node B |
|------|--------|--------|--------|
| s1-bgw1 Eth1/1 <-> s1-leaf1 Eth1/1 | 10.1.1.0/30 | .1 | .2 |
| s1-bgw1 Eth1/2 <-> s1-leaf2 Eth1/1 | 10.1.2.0/30 | .1 | .2 |
| s1-bgw2 Eth1/1 <-> s1-leaf1 Eth1/2 | 10.1.3.0/30 | .1 | .2 |
| s1-bgw2 Eth1/2 <-> s1-leaf2 Eth1/2 | 10.1.4.0/30 | .1 | .2 |

### Site 2 (OSPF UNDERLAY, area 0.0.0.0, P2P, MTU 9150)
| Link | Subnet | Node A | Node B |
|------|--------|--------|--------|
| s2-bgw1 Eth1/1 <-> s2-leaf1 Eth1/1 | 10.2.1.0/30 | .1 | .2 |
| s2-bgw1 Eth1/2 <-> s2-leaf2 Eth1/1 | 10.2.2.0/30 | .1 | .2 |
| s2-bgw2 Eth1/1 <-> s2-leaf1 Eth1/2 | 10.2.3.0/30 | .1 | .2 |
| s2-bgw2 Eth1/2 <-> s2-leaf2 Eth1/2 | 10.2.4.0/30 | .1 | .2 |

### DCI Links (full mesh, `evpn multisite dci-tracking`)
| Link | Subnet | Site 1 BGW | Site 2 BGW |
|------|--------|-----------|-----------|
| s1-bgw1 Eth1/5 <-> s2-bgw1 Eth1/5 | 172.16.0.0/30 | .1 | .2 |
| s1-bgw2 Eth1/5 <-> s2-bgw2 Eth1/5 | 172.16.1.0/30 | .1 | .2 |
| s1-bgw1 Eth1/6 <-> s2-bgw2 Eth1/6 | 172.16.2.0/30 | .1 | .2 |
| s1-bgw2 Eth1/6 <-> s2-bgw1 Eth1/6 | 172.16.3.0/30 | .1 | .2 |

## Servers

| Server | Site | Connected To | VLAN | VNI | IP |
|--------|------|-------------|------|-----|----|
| srv1 | 1 | s1-leaf1 Eth1/10 | 10 | 100010 | 192.168.10.1/24 |
| srv2 | 1 | s1-leaf2 Eth1/10 | 10 | 100010 | 192.168.10.2/24 |
| srv3 | 2 | s2-leaf1 Eth1/10 | 10 | 100010 | 192.168.10.3/24 |
| srv4 | 2 | s2-leaf2 Eth1/10 | 10 | 100010 | 192.168.10.4/24 |
| srv5 | 1 | s1-leaf1 Eth1/11 | 10 | 100010 | 192.168.10.5/24 |
| srv6 | 2 | s2-leaf1 Eth1/11 | 10 | 100010 | 192.168.10.6/24 |

## Architecture

### Protocol Stack
| Layer | Protocol | Details |
|-------|----------|---------|
| Underlay | OSPF | Area 0, P2P links, MTU 9150 |
| Overlay Control | BGP EVPN (l2vpn evpn) | iBGP within site (RR on BGWs), eBGP over DCI |
| Data Plane | VXLAN | VNI 100010, ingress-replication BGP |
| DCI | eBGP EVPN | `peer-type fabric-external`, ebgp-multihop 5, loopback100 source |

### BGP Design
- **Intra-site**: BGWs are route reflectors; leaves peer to both BGWs as iBGP clients
- **Inter-site**: BGWs peer eBGP to both remote BGWs using loopback0 as update-source
- **Multisite loopback100**: Anycast address shared by both BGWs per site; used as `multisite border-gateway interface loopback100` on the NVE
- **OSPF redistribution**: `redistribute static route-map PERMIT_ALL` on BGWs redistributes static routes for remote loopback100 into the local underlay so leaves can resolve the remote VTEP

### VLAN / VNI
| VLAN | Name | VNI | Route Targets |
|------|------|-----|--------------|
| 10 | TENANT-A | 100010 | import/export 1:100010 |

## Requirements

- [Containerlab](https://containerlab.dev) >= 0.54.2
- Docker >= 24.0
- Cisco N9Kv image: `vrnetlab/cisco_n9kv:9300v-9.3.16` (built with [vrnetlab](https://github.com/hellt/vrnetlab))

## Deploy

```bash
sudo containerlab deploy -t multisite-vxlan.clab.yml
```

> Boot time: ~8-10 minutes for all 8 N9Kv nodes to reach healthy state.

## Verify

```bash
# BGW multisite state
show nve multisite dci-links
show nve multisite fabric-links
show bgp l2vpn evpn summary

# Leaf NVE peers and MAC table
show nve peers
show mac address-table

# Cross-site ping: srv5 (site 1) -> srv6 (site 2), same VLAN 10
docker exec clab-multisite-vxlan-srv5 ping 192.168.10.6
```

## Destroy

```bash
sudo containerlab destroy -t multisite-vxlan.clab.yml --cleanup
```

## License

BSD 3-Clause License
