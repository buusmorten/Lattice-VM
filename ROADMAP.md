# Roadmap

Lattice VM is currently establishing a safe, maintainable foundation for an
independent UTM fork.

## Foundation

- Continue auditing the user-facing rebrand without breaking VM compatibility.
- Document reproducible dependency and application builds.
- Establish CI for supported Apple platforms.
- Audit third-party dependencies, assets, notices, and redistribution duties.
- Define a stable migration and compatibility policy.

## Installation experience

- Harden the macOS restore catalog with availability and signing-state
  indicators.
- Add resumable downloads, checksum verification, cache management, and a
  retry action for Apple installation-service failures.
- Improve official Windows and Linux source discovery without mirroring or
  redistributing vendor media.
- Add clearer host/guest architecture and compatibility checks before large
  downloads begin.

## Networking

- Refine the network profiles, topology summary, validation, preflight
  diagnostics, DNS ordering, and safe port-forward presets.
- Add live reachability and service probes for running guests.
- Implement backend support for static DHCP reservations before exposing them
  in the UI.
- Explore packet capture and network-condition simulation.

## User experience

- Modernize VM creation and settings.
- Improve first-run guidance and error recovery.
- Add clearer distinctions between QEMU and Apple Virtualization capabilities.
- Improve accessibility and localization coverage.
- Detect missing guest tools and show actionable shared-folder auto-mount
  status instead of relying only on logs.

This roadmap is directional rather than a release promise. Proposals should be
discussed in an issue before substantial implementation work begins.
