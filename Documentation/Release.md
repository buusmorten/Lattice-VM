# Release guide

Lattice VM does not yet publish supported binary releases. Do not create a
public release until the dependency-license audit, signing setup, and release
workflow have been completed.

## Release prerequisites

- Audit the exact QEMU, SPICE, GStreamer, firmware, and Swift dependency set.
- Satisfy all Apache, GPL, LGPL, MIT, BSD, and asset-license obligations.
- Build and test macOS, iOS, iPadOS, and visionOS targets that will be shipped.
- Verify VM migration and existing `.utm` bundle compatibility.
- Configure independent Lattice VM signing identities and bundle identifiers.
- Generate checksums and a software bill of materials.
- Review [SECURITY.md](../SECURITY.md) and
  [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Versioning

Update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in
`Build.xcconfig`. The current developer-preview line is `0.1.x`; use semantic
versioning for public releases and increment the build number for every
distributed artifact.

## Validation

Build through `.github/workflows/build.yml`, verify every artifact on clean
hardware, and document known limitations. Never redistribute operating-system
images, proprietary firmware, or user VM data.

Before publishing, test all official-source wizard links, a macOS IPSW download
through restore-service handoff, local Windows and Linux ISO imports, both VM
backends, and the entitlements on the final signed app. Packaging scripts still
contain inherited `UTM.*` intermediate/output names; either document them for a
developer preview or rename and verify the scripts before a branded release.
