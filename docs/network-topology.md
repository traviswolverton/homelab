# Network Topology

Last updated: 2026-03

## Core Equipment

| Device | Role | Location |
|--------|------|----------|
| UCG-Fiber | Gateway / router | Rack U1 |
| UniFi Pro Max 16 PoE | Core switch | Rack U2 |
| U7 Pro AP × 2 | Wireless | AP1, AP2 |
| Flex Mini 2.5G | Office sub-switch | Office |
| US-8-60W | Living room sub-switch | Living room |
| US-8-150W | Playroom sub-switch | Playroom |

## UCG-Fiber Port Assignments (2.5G ports)

| Port | Assignment |
|------|-----------|
| 1 | Living Room |
| 2 | Master Bedroom |
| 3 | Kitchen |
| 4 | Playroom Cat6a (freed after fiber) |

> Proxmox connects directly to switch SFP+18, not UCG — keeps LAN traffic off router.

## Pro Max 16 PoE Port Assignments

### GbE PoE+ Ports (1–12)
Patch panel → room runs, cameras, clients via keystone panel.

### 2.5G PoE++ Ports (13–16)

| Port | Assignment | Notes |
|------|-----------|-------|
| 13 | Office Cat5e | Powers Flex Mini 2.5G |
| 14 | AP1 U7 Pro | |
| 15 | AP2 U7 Pro | |
| 16 | Free | |

### SFP+ Ports (17–18)

| Port | Assignment | Notes |
|------|-----------|-------|
| 17 | UCG-Fiber | DAC cable uplink |
| 18 | Proxmox fiber | 10G direct — LAN traffic stays on switch |

## Room Endpoints

| Room | Switch | Devices |
|------|--------|---------|
| Living Room | US-8-60W | Apple TV, Xbox, Nintendo Switch 2 |
| Kitchen | — | No device (run terminated at keystone) |
| Master Bedroom | — | Smart TV direct |
| Office | Flex Mini 2.5G | Desktop, PS5, laptop (2.5G), work laptop — all 4 ports used |
| Playroom | US-8-150W | PS5, TV, misc + Proxmox fiber direct |

## Keystone Panel Color Convention

| Color | Category | Examples |
|-------|----------|---------|
| Yellow | Legacy / non-Cat6 | ISP WAN, Cat5e room runs, kitchen run, camera runs, NVR uplink |
| Black (Blue) | Cat6 infrastructure / PoE | APs, PoE spares |
| White | Cat6 wired clients | Wired client drops |
| Purple | Fiber | Active fiber run, reserved |
| Orange | Coax | Antenna, HD Homerun, room runs |

## Patch Panel Layout (2U 48-port)

### U4 — Row 1 (Ports 1–24)

| Ports | Color | Assignment |
|-------|-------|-----------|
| 01 | Yellow | ISP WAN |
| 02–05 | Yellow | Room runs (Cat5e) incl. kitchen |
| 06 | Yellow | NVR uplink |
| 07–08 | Black | APs |
| 09–12 | Black | PoE spares |
| 15–18 | White | Wired clients |
| 19 | Purple | Fiber (active) |
| 20 | Purple | Fiber (reserved) |

### U5 — Row 2 (Ports 1–24)

| Ports | Color | Assignment |
|-------|-------|-----------|
| 01–05 | Orange | Coax (antenna in, HD Homerun, room runs × 3) |
| 06–13 | Yellow | CAM1–CAM8 |
| 14–24 | — | Empty / future expansion |

## Coax Signal Chain

```
Antenna → Keystone IN (U5:01) → Splitter/Power Inserter (velcro rear U6-7)
    ├── HD Homerun Duo (U5:02 → shelf U3)
    └── Room runs × 3 (U5:03–05)
```

## DNS

- Primary: Pi-hole on main Proxmox node (pihole-1)
- Secondary: Pi-hole on RPi infrastructure node (pihole-2)
- Future: Migrate from USG built-in DNS to Pi-hole fully

## Planned Upgrades

- [ ] UCG-Fiber gateway deployment (rack U1)
- [ ] UniFi Pro Max 16 PoE deployment (rack U2)
- [ ] 2.5G AP support via PoE++ ports
- [ ] Full DNS migration to Pi-hole
