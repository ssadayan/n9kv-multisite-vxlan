# n9kv-multisite-vxlan

A containerlab lab demonstrating **Multi-Site VXLAN/EVPN** across two data center sites using Cisco Nexus 9000v.

## Topology

```
  ┌──────────────────── Site 1 (AS 65001) ────────────────────┐
  │                                                            │
  │         spine1 (10.1.0.1)  [Route Reflector]              │
  │          /           \                                     │
  │    bgw1 (10.1.0.2)  leaf1 (10.1.0.11)  leaf2 (10.1.0.12) │
  │    [BGW+VTEP]         |                  |                 │
  │       |            server1            server2              │
  │       | DCI         VLAN10             VLAN20              │
  │       |          192.168.10.1       192.168.20.2           │
  └───────┼────────────────────────────────────────────────────┘
          │ 192.168.100.0/30
  ┌───────┼────────────────────────────────────────────────────┐
  │       |                                                    │
  │    bgw2 (10.2.0.2)  leaf3 (10.2.0.11)  leaf4 (10.2.0.12) │
  │    [BGW+VTEP]         |                  |                 │
  │          \          server3            server4             │
  │         spine2 (10.2.0.1)  [Route Reflector]              │
  │                                                            │
  └──────────────────── Site 2 (AS 65002) ────────────────────┘
```

## Architecture

### Multi-Site Design
- **Border Gateways (BGW)**: bgw1 and bgw2 connect the two sites over a DCI link
- **Route Re-origination**: BGWs re-originate EVPN routes between sites using `rewrite-evpn-rt-asn`
- **Stretched VLANs**: VLAN 10 and VLAN 20 are stretched across both sites
- **Anycast Gateway**: Same gateway IP/MAC used on both sites for seamless VM mobility

### Protocol Stack
| Layer | Protocol | Details |
|-------|----------|---------|
| Underlay | OSPF | Area 0, P2P links, MTU 9150 |
| Overlay Control | BGP EVPN | iBGP within site, eBGP over DCI |
| Data Plane | VXLAN | Ingress replication, BGP control plane |
| DCI | eBGP EVPN | `peer-type fabric-external`, ebgp-multihop 5 |

### IP Addressing

#### Site 1 Underlay
| Link | Subnet | Node A | Node B |
|------|--------|--------|--------|
| spine1 ↔ bgw1 | 10.10.1.0/30 | .1 | .2 |
| spine1 ↔ leaf1 | 10.10.2.0/30 | .1 | .2 |
| spine1 ↔ leaf2 | 10.10.3.0/30 | .1 | .2 |

#### Site 2 Underlay
| Link | Subnet | Node A | Node B |
|------|--------|--------|--------|
| spine2 ↔ bgw2 | 10.20.1.0/30 | .1 | .2 |
| spine2 ↔ leaf3 | 10.20.2.0/30 | .1 | .2 |
| spine2 ↔ leaf4 | 10.20.3.0/30 | .1 | .2 |

#### DCI
| Link | Subnet | bgw1 | bgw2 |
|------|--------|------|------|
| bgw1 ↔ bgw2 | 192.168.100.0/30 | .1 | .2 |

#### Loopbacks
| Node | lo0 (VTEP) | lo100 (DCI source) |
|------|-----------|-------------------|
| spine1 | 10.1.0.1/32 | - |
| bgw1 | 10.1.0.2/32 | 1.1.1.1/32 |
| leaf1 | 10.1.0.11/32 | - |
| leaf2 | 10.1.0.12/32 | - |
| spine2 | 10.2.0.1/32 | - |
| bgw2 | 10.2.0.2/32 | 2.2.2.2/32 |
| leaf3 | 10.2.0.11/32 | - |
| leaf4 | 10.2.0.12/32 | - |

### VLAN / VNI / Server Mapping
| Server | Site | Leaf | VLAN | VNI | IP |
|--------|------|------|------|-----|----|
| server1 | 1 | leaf1 | 10 | 100010 | 192.168.10.1/24 |
| server2 | 1 | leaf2 | 20 | 100020 | 192.168.20.2/24 |
| server3 | 2 | leaf3 | 10 | 100010 | 192.168.10.3/24 |
| server4 | 2 | leaf4 | 20 | 100020 | 192.168.20.4/24 |

## Requirements

- [Containerlab](https://containerlab.dev) >= 0.54.2
- Docker >= 24.0.5
- Cisco N9KV image: `vrnetlab/vr-n9kv:9.3.13` (must be built with [vrnetlab](https://github.com/hellt/vrnetlab))

## Deploy

```bash
# Clone the repo
git clone https://github.com/<your-username>/n9kv-multisite-vxlan
cd n9kv-multisite-vxlan

# Deploy
sudo containerlab deploy -t n9kv-multisite-vxlan.clab.yml

# Verify
sudo containerlab inspect
```

> Estimated deploy time: ~8 minutes on bare-metal hardware.

## Connect to Nodes

```bash
# SSH to any node (password: admin)
ssh admin@clab-n9kv-multisite-vxlan-spine1
ssh admin@clab-n9kv-multisite-vxlan-bgw1
ssh admin@clab-n9kv-multisite-vxlan-leaf1

# Docker exec
docker exec -it clab-n9kv-multisite-vxlan-spine1 vtysh
```

## Verify Multi-Site VXLAN

```bash
# On bgw1 - check multisite state
show nve multisite dci-links
show nve multisite fabric-links
show bgp l2vpn evpn summary

# On leaf1 - verify VTEP table
show nve peers
show mac address-table

# Cross-site ping (server1 -> server3, same VLAN 10, different sites)
# From server1:
ping 192.168.10.3
```

## Destroy

```bash
sudo containerlab destroy -t n9kv-multisite-vxlan.clab.yml --cleanup
```

## License

BSD 3-Clause License
