# Security policy

## Supported versions

Lattice VM is an early-stage fork and does not currently publish supported
binary releases. Security fixes are applied to the latest development branch.

## Reporting a vulnerability

Do not open a public issue containing vulnerability details.

Use GitHub's private vulnerability reporting feature for this repository. If
that feature is unavailable, open a minimal issue asking the maintainer to
establish a private communication channel without including technical details.

Include affected versions or commits, reproduction steps, impact, and any
suggested mitigation. Reports will be acknowledged as capacity permits.

Vulnerabilities originating in upstream UTM, QEMU, SPICE, or another dependency
should also be reported through that project's security process when
appropriate.

## Download trust

The macOS catalog supplies metadata, but Lattice VM accepts automatic IPSW
downloads only from Apple-controlled HTTPS hosts and validates the file header
before restore-service handoff. Windows and Linux selectors open official
vendor pages and require an explicit local image import.

Do not report a vendor image becoming unavailable as a Lattice VM security
issue. Do report catalog spoofing, host-validation bypasses, unsafe archive
handling, sandbox escapes, unintended network exposure, or credential leakage
through GitHub's private vulnerability channel.
