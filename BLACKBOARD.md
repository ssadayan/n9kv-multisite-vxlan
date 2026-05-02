# BLACKBOARD — VXLAN EVPN Multisite Lab
> Shared context document for agents. Read this to get full situational awareness of the project.

---

## What This Project Is

A **containerlab-based VXLAN EVPN Multisite lab** using Cisco Nexus 9000v (N9kv) virtual nodes.
Two data-center sites are interconnected via a Border Gateway (BGW) node per site over a DCI link.
A stretched Layer 2 segment (VLAN 10, VNI 100010, 192.168.10.0/24) spans both sites.

**Lab location:** `lab-examples/multisite-vxlan/` in the containerlab repo.

---

## File Inventory

```
lab-examples/multisite-vxlan/
├── multisite-vxlan.clab.yml          # Containerlab topology definition
├── multisite-vxlan-vsg.html          # VSG slide presentation (HTML, open in browser)
├── BLACKBOARD.md                     # This file — shared agent context
└── configs/
    ├── s1-spine1.cfg                 # Site 1 spine 1 NX-OS startup config
    ├── s1-spine2.cfg                 # Site 1 spine 2
    ├── s1-leaf1.cfg                  # Site 1 leaf 1 (serves srv1)
    ├── s1-leaf2.cfg                  # Site 1 leaf 2 (serves srv2)
    ├── s1-bgw1.cfg                   # Site 1 Border Gateway
    ├── s2-spine1.cfg                 # Site 2 spine 1
    ├── s2-spine2.cfg                 # Site 2 spine 2
    ├── s2-leaf1.cfg                  # Site 2 leaf 1 (serves srv3)
    ├── s2-leaf2.cfg                  # Site 2 leaf 2 (serves srv4)
    └── s2-bgw1.cfg                   # Site 2 Border Gateway
```

---

## Topology

```
SITE 1 (AS 65001, Site-ID 1)          SITE 2 (AS 65002, Site-ID 2)
┌────────────────────────┐             ┌────────────────────────┐
│  s1-spine1  s1-spine2  │             │  s2-spine1  s2-spine2  │
│       \        /       │             │       \        /       │
│   s1-leaf1  s1-leaf2  s1-bgw1──DCI──s2-bgw1  s2-leaf1 s2-leaf2 │
│      |          |                               |         |   │
│    srv1        srv2                           srv3       srv4  │
└────────────────────────┘             └────────────────────────┘
```

**DCI link:** s1-bgw1:eth5 ↔ s2-bgw1:eth5 — 172.16.0.0/30

---

## Node Summary

| Node       | Role              | AS    | lo0          | lo1 (NVE)      | lo100 (Multisite)  |
|------------|-------------------|-------|--------------|----------------|--------------------|
| s1-spine1  | Spine / RR        | 65001 | 10.1.0.1/32  | —              | —                  |
| s1-spine2  | Spine / RR        | 65001 | 10.1.0.2/32  | —              | —                  |
| s1-leaf1   | Leaf / VTEP       | 65001 | 10.1.0.11/32 | 10.1.0.111/32  | —                  |
| s1-leaf2   | Leaf / VTEP       | 65001 | 10.1.0.12/32 | 10.1.0.112/32  | —                  |
| s1-bgw1    | Border Gateway    | 65001 | 10.1.0.21/32 | 10.1.0.121/32  | 10.1.100.21/32     |
| s2-spine1  | Spine / RR        | 65002 | 10.2.0.1/32  | —              | —                  |
| s2-spine2  | Spine / RR        | 65002 | 10.2.0.2/32  | —              | —                  |
| s2-leaf1   | Leaf / VTEP       | 65002 | 10.2.0.11/32 | 10.2.0.111/32  | —                  |
| s2-leaf2   | Leaf / VTEP       | 65002 | 10.2.0.12/32 | 10.2.0.112/32  | —                  |
| s2-bgw1    | Border Gateway    | 65002 | 10.2.0.21/32 | 10.2.0.121/32  | 10.2.100.21/32     |
| srv1–srv4  | Linux test hosts  | —     | —            | —              | —                  |

**Server IPs:** srv1=192.168.10.1, srv2=192.168.10.2, srv3=192.168.10.3, srv4=192.168.10.4
All in VLAN 10 / VNI 100010 / subnet 192.168.10.0/24 — stretched across both sites.

---

## P2P Link Addressing

### Site 1
| Link                    | Subnet        | Side A (.x) | Side B (.y) |
|-------------------------|---------------|-------------|-------------|
| s1-spine1 ↔ s1-leaf1    | 10.1.1.0/30   | spine1 .1   | leaf1 .2    |
| s1-spine1 ↔ s1-leaf2    | 10.1.2.0/30   | spine1 .1   | leaf2 .2    |
| s1-spine1 ↔ s1-bgw1     | 10.1.3.0/30   | spine1 .1   | bgw1 .2     |
| s1-spine2 ↔ s1-leaf1    | 10.1.4.0/30   | spine2 .1   | leaf1 .2    |
| s1-spine2 ↔ s1-leaf2    | 10.1.5.0/30   | spine2 .1   | leaf2 .2    |
| s1-spine2 ↔ s1-bgw1     | 10.1.6.0/30   | spine2 .1   | bgw1 .2     |

### Site 2
| Link                    | Subnet        | Side A (.x) | Side B (.y) |
|-------------------------|---------------|-------------|-------------|
| s2-spine1 ↔ s2-leaf1    | 10.2.1.0/30   | spine1 .1   | leaf1 .2    |
| s2-spine1 ↔ s2-leaf2    | 10.2.2.0/30   | spine1 .1   | leaf2 .2    |
| s2-spine1 ↔ s2-bgw1     | 10.2.3.0/30   | spine1 .1   | bgw1 .2     |
| s2-spine2 ↔ s2-leaf1    | 10.2.4.0/30   | spine2 .1   | leaf1 .2    |
| s2-spine2 ↔ s2-leaf2    | 10.2.5.0/30   | spine2 .1   | leaf2 .2    |
| s2-spine2 ↔ s2-bgw1     | 10.2.6.0/30   | spine2 .1   | bgw1 .2     |

### DCI
| Link              | Subnet       | s1-bgw1 | s2-bgw1 |
|-------------------|--------------|---------|---------|
| s1-bgw1 ↔ s2-bgw1 | 172.16.0.0/30 | .1     | .2      |

---

## Protocol Stack

### Underlay (per site)
- **Protocol:** OSPF, process name `UNDERLAY`, area 0
- **Interface type:** point-to-point on all fabric links
- **MTU:** 9150 on all fabric p2p links
- **In OSPF:** loopback0 (RID) + loopback1 (NVE VTEP source)
- **NOT in OSPF:** loopback100 (multisite BGW), DCI link

### Overlay (per site)
- **Protocol:** iBGP l2vpn evpn
- **Route Reflectors:** Both spines per site (`retain route-target all`)
- **RR Clients:** Leaves + BGW (peer via loopback0 to both spines)
- **VNI:** VLAN 10 → VNI 100010
- **Route Target:** `1:100010` — **same on both sites** (critical for cross-site import)
- **NVE source:** loopback1
- **Features:** ARP suppression, BGP ingress replication

### Inter-Site (BGW to BGW)
- **Protocol:** eBGP l2vpn evpn between s1-bgw1 and s2-bgw1
- **Session endpoints:** loopback100 addresses (10.1.100.21 ↔ 10.2.100.21)
- **Reachability:** static routes via DCI link (`ip route 10.x.100.21/32 172.16.0.x`)
- **BGP options:** `update-source loopback100`, `ebgp-multihop 5`

---

## Key NX-OS Multisite Commands

```
! Enable multisite on BGW
evpn multisite border-gateway <site-id>   # site-id: 1 for site1, 2 for site2

! Interface roles
evpn multisite fabric-tracking            # on spine-facing interfaces
evpn multisite dci-tracking              # on DCI interface

! NVE multisite loopback
interface nve1
  multisite border-gateway interface loopback100

! BGP
router bgp <as>
  address-family l2vpn evpn
    advertise-pip
```

---

## Containerlab Interface Mapping

NX-OS ↔ containerlab (vrnetlab n9kv):
- `Ethernet1/1` = `eth1` in clab YAML
- `Ethernet1/2` = `eth2`
- `Ethernet1/5` = `eth5` (DCI link)
- `Ethernet1/10` = `eth10` (server access)

---

## How to Deploy

```bash
# From repo root:
cd /Users/ssadayan/containerlab
clab deploy -t lab-examples/multisite-vxlan/multisite-vxlan.clab.yml

# SSH into a node (default creds: admin/admin):
ssh admin@clab-multisite-vxlan-s1-leaf1

# Test cross-site connectivity:
docker exec clab-multisite-vxlan-srv1 ping 192.168.10.3 -c 5
```

---

## Verification Checklist

1. `show bgp l2vpn evpn summary` — all EVPN BGP sessions up (spines + remote BGW)
2. `show nve vni` — VNI 100010 in UP state
3. `show nve peers` — see remote site BGW loopback100 as a peer on BGW nodes
4. `show bgp l2vpn evpn` — routes from remote site present (rd from 10.2.0.x)
5. `ping 192.168.10.3` from srv1 — cross-site L2 connectivity confirmed
6. `show nve multisite dci-links` — DCI link tracked and active
7. `show nve multisite fabric-links` — fabric-tracking links active

---

## Design Decisions (Rationale)

| Decision | Why |
|----------|-----|
| Shared RT `1:100010` | Avoids `rewrite-evpn-rt-asn` — routes accepted cross-site without BGP policy |
| Separate loopback100 per BGW | Multisite VTEP identity isolated from RID and NVE VTEP; not redistributed into underlay |
| OSPF scoped per site only | Clean boundary; static route covers lo100 reachability; simpler troubleshooting |
| MTU 9150 on fabric links | VXLAN overhead = 50B; 9000B tenant + 50B overhead requires fabric MTU > 9050 |
| Access ports for servers | Simpler than VLAN trunks for L2 stretch verification; no 802.1q on Linux hosts needed |

---

## Known Constraints

- N9kv in vrnetlab is resource-intensive — each VM needs ~4GB RAM; 11 nodes = ~44GB RAM minimum
- Boot time for N9kv is slow (5–10 min); configs are applied from startup-config at first boot
- `evpn multisite border-gateway` requires NX-OS 9.2+ on Nexus 9300/9500 platforms (9kv supports it)
- The lab uses a single BGW per site — production deployments use 2 BGWs for redundancy (vPC pair)
