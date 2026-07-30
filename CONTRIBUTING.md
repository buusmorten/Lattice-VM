# Contributing to Lattice VM

Contributions are welcome. Lattice VM is an independent UTM fork, so check both
this repository and upstream UTM before starting substantial work.

## Before coding

1. Search existing issues.
2. Open an issue for significant features or architecture changes.
3. Keep each pull request focused on one feature or fix.
4. Preserve compatibility with existing `.utm` bundles unless a migration is
   documented and tested.

## Development

The project uses Swift, SwiftUI, QEMU, SPICE, and Apple
Virtualization.framework. Read:

- [Architecture](Documentation/Architecture.md)
- [macOS development](Documentation/MacDevelopment.md)
- [iOS development](Documentation/iOSDevelopment.md)
- [Dependencies](Documentation/Dependencies.md)

Prebuilt `sysroot-*` dependencies are required for normal application builds.
Do not rebuild QEMU or SPICE unless the change specifically affects them.

Follow the Swift API Design Guidelines. Prefer clear user-facing language,
safe defaults, and platform-native behavior. Keep backend-specific features
explicit: QEMU and Apple Virtualization do not expose identical capabilities.

## Testing

Describe the hardware, operating-system version, VM backend, guest OS, and
manual test procedure in the pull request. Run the most relevant available
builds and checks. If a required dependency prevents a check, state that
clearly.

Changes to the creation wizard should test local image import as well as any
official-source selector they affect. macOS restore changes must cover download
completion, IPSW validation, Apple restore-service handoff, and a failed or
unsupported image. Networking changes should test both QEMU and Apple
Virtualization because their available controls differ.

## Commits and pull requests

Use commit subjects in the form `component: concise purpose`. Explain why the
change is needed and include issue references where applicable.

AI-assisted commits must include:

```text
Assisted-by: TOOL:MODEL
```

Do not use `Co-authored-by` for AI tools. The human contributor remains
responsible for reviewing and testing every submitted change.

## Upstream work

When a fix also applies to UTM, link the relevant upstream issue or pull
request. Do not imply that Lattice VM changes are endorsed by UTM maintainers.

By contributing, you agree that your contribution is licensed under the
repository's [Apache License 2.0](LICENSE).
