# Networking

Lattice VM supports two networking backends with different capabilities.

## QEMU

QEMU networking provides Shared, Bridged, Host Only, and Emulated VLAN modes.
The settings interface includes:

- Plain-language mode descriptions and a topology summary.
- Internet Only, Visible on LAN, Development, Isolated Lab, and Offline
  profiles.
- IPv4 subnet, gateway, DHCP, IPv6, DNS, search-domain, and local-domain
  settings where supported.
- Subnet, DHCP-range, gateway, MAC-address, and port-forward validation.
- SSH, HTTP, HTTPS, RDP, and VNC forwarding presets.
- Localhost-only forwarding and LAN-exposure warnings.
- Configuration preflight diagnostics and detected guest addresses.
- A safe preview of generated QEMU network arguments.

Existing configuration keys remain compatible with UTM. Lattice-specific keys
are optional and older builds ignore them.

## Apple Virtualization

Apple Virtualization exposes Shared and Bridged modes. DHCP, DNS, packet
capture, firewall, shaping, and port forwarding are controlled by macOS or the
physical network and are not configurable through Virtualization.framework.
Configure static addressing and custom DNS inside the guest.

## Backend-dependent roadmap

Static DHCP reservations, packet capture, per-VM firewalling, traffic shaping,
VPN attachment, recording/replay, and IPv6 translation require changes below
the current UI layer. They must be implemented in vmnet, libslirp/QEMU, or a
separate privileged networking service before the controls can be safely
offered. Lattice VM does not display nonfunctional switches for these features.

Reusable host networks can be created in Lattice VM Settings and selected by
multiple QEMU VMs. Shared host networks do not provide DHCP; configure guest
addresses manually.

Shared folders are separate from VM network adapters. SPICE WebDAV uses a
guest-local endpoint supplied through the SPICE channel; enabling its automatic
desktop link does not expose the host folder to the LAN.

## Safety and troubleshooting

Port forwards bind to localhost by default. Binding to all interfaces can
expose a guest service to the local network and should be deliberate. Bridged
networking also requires the appropriate signed entitlement; an ad-hoc or
unsigned development build may show fewer capabilities.

If a guest has no connectivity, confirm the selected backend and mode first,
then review the preflight diagnostics, guest address, subnet, DHCP range, and
host port conflicts. Apple Virtualization network problems generally must be
diagnosed in macOS or inside the guest because its framework does not expose
QEMU's detailed controls.
