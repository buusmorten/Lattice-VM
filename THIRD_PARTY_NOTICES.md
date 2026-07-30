# Third-party notices

Lattice VM is an independent derivative of
[UTM](https://github.com/utmapp/UTM). The repository preserves the upstream Git
history, copyright notices, and Apache License 2.0 license.

The application incorporates or depends upon separately licensed software,
including QEMU, SPICE, GStreamer, libslirp, SwiftTerm, ZIP Foundation,
IQKeyboardManager, and InAppSettingsKit. Depending on the selected target and
build configuration, additional dependencies and firmware may be included.

Relevant licenses include Apache-2.0, GPL, LGPL, MIT, BSD, and other
component-specific terms. Files under `patches/`, dependency build scripts, and
generated sysroot contents identify further upstream sources.

This document is an overview, not a substitute for the copyright and license
notices shipped with each component. Anyone distributing compiled builds must
audit the exact dependency versions and linking methods in that build and
provide source, notices, relinking materials, or written offers where the
applicable licenses require them.

Operating-system installers, recovery images, firmware, and user-created
virtual machine images are not licensed by this repository and must not be
redistributed without separate authorization.

The macOS release picker uses version metadata from
[IPSW Downloads](https://ipsw.me/) and accepts restore-image download URLs only
on Apple-controlled HTTPS hosts. Windows and Linux choices link to official
Microsoft or distribution download pages. No operating-system image is bundled
with Lattice VM.
