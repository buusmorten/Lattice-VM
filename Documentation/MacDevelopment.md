# macOS Development

Lattice VM is a sandboxed macOS app and requires additional native
dependencies and signing configuration.

## Getting the Source

Make sure you perform a recursive clone to get all the submodules:
```sh
git clone --recursive https://github.com/buusmorten/Lattice-VM.git
```

Alternatively, run the following after cloning if you did not do a recursive clone.
```sh
git submodule update --init --recursive
```

## Dependencies

The easy way is to get the prebuilt dependencies from [GitHub Actions][1]. Pick the latest release and download all of the `Sysroot-macos-*` artifacts. You need to be logged in to GitHub to download artifacts. If you only intend to run locally, it is alright to just download the sysroot for your architecture. After downloading the prebuilt artifacts of your choice, extract them to the root directory where you cloned the repository.

Use the latest supported stable Xcode release. Open `LatticeVM.xcodeproj` for
interactive development. Many internal source types retain their UTM names for
source and virtual-machine compatibility.

### Building Dependencies (Advanced)

If you want to build the dependencies yourself, it is highly recommended that you start with a fresh macOS VM. This is because some of the dependencies attempt to use `/usr/local/lib` even though the architecture does not match. Certain installed packages like `libusb`, `gawk`, and `cmake` will break the build.

1. Install Xcode command line and [Homebrew][1]
2. Install the following build prerequisites
    ```sh
    brew install bison pkg-config gettext glib-utils libgpg-error nasm meson
    ```
    
    ```sh
    pip3 install six pyparsing
    ```
    
    Make sure to add `bison` to your `$PATH` environment variable!
    
    ```sh
    export PATH=/usr/local/opt/bison/bin:/opt/homebrew/opt/bison/bin:$PATH
    ```
3. Run
    ```sh
    ./scripts/build_dependencies.sh -p macos -a ARCH
    ```
    where `ARCH` is either `arm64` or `x86_64`.

If you want to build universal binaries, you need to run `build_dependencies.sh` for both `arm64` and `x86_64` and then run

```sh
./scripts/pack_dependencies.sh . macos arm64 x86_64
```

If you are developing QEMU and wish to pass in a custom path to QEMU, you can use the `-q PATH_TO_QEMU_SOURCE` option to `build_dependencies.sh`. Note that you need to use a UTM compatible fork of QEMU.

## Building Lattice VM

### Command Line

Build the inherited macOS scheme with:

```sh
./scripts/build_utm.sh -t TEAMID -k macosx -s macOS -a ARCH -o /path/to/output/directory
```

`ARCH` can be `x86_64` or `arm64` or `"arm64 x86_64"` (quotes are required) for a universal binary. The built artifact is an unsigned `.xcarchive` which you can use with the package tool (see below).

`TEAMID` is optional and only used if you are going to sign it.

For a direct Xcode build:

```sh
xcodebuild -project LatticeVM.xcodeproj \
  -scheme macOS \
  -configuration Debug \
  build
```

### Packaging

Artifacts built with `build_utm.sh` (includes GitHub Actions artifacts) must be re-signed before it can be used. To properly use all features, you must be a paid Apple Developer with access to a provisioning profile with the Hypervisor entitlements. However, non-registered developers can build "unsigned" packages which lack certain features (such as USB and network bridging support).

#### Unsigned packages

```sh
./scripts/package_mac.sh unsigned /path/to/UTM.xcarchive /path/to/output
```
where `/path/to/output` is an existing directory.

This builds `UTM.dmg` in `/path/to/output` which can be installed to `/Applications`.

`UTM.xcarchive`, `UTM.dmg`, and `UTM.pkg` are inherited packaging-script
filenames. The built application product is Lattice VM. Do not rename an
artifact in documentation without updating and testing the corresponding
script.

#### Signed packages

```sh
./scripts/package_mac.sh developer-id /path/to/UTM.xcarchive /path/to/output TEAM_ID PROFILE_UUID HELPER_PROFILE_UUID LAUNCHER_PROFILE_UUID
```
where `/path/to/output` is an existing directory.

To build a signed package, you need to be a registered Apple Developer. From the developer portal, create a certificate for "Developer ID Application" (and install it into your Keychain). Also create three provisioning profiles with that certificate with Hypervisor entitlements (you need to manually request these entitlements and be approved by Apple) for UTM, QEMUHelper, and QEMULauncher. `TEAM_ID` should be the same as in the certificate, `PROFILE_UUID` should be the UUID of the profile installed by Xcode (open the profile in Xcode), and `HELPER_PROFILE_UUID` is the UUID of a separate profile for the XPC helper. `LAUNCHER_PROFILE_UUID` is the UUID of a profile for the launcher.

Once properly signed, you can ask Apple to notarize the DMG.

#### Mac App Store

```sh
./scripts/package_mac.sh app-store /path/to/UTM.xcarchive /path/to/output TEAM_ID PROFILE_UUID HELPER_PROFILE_UUID LAUNCHER_PROFILE_UUID
```

Similar to the above but builds a `UTM.pkg` for submission to the Mac App Store. You need a certificate for "Apple Distribution" and a certificate for "Mac App Distribution" as well as a provisioning profile with the right entitlements.

### Xcode Development

By default, Xcode will build Lattice VM unsigned (lacking USB and bridged networking features).

If you have a registered developer account with access to Hypervisor entitlements, you should create a `CodeSigning.xcconfig` file with the proper values (see `CodeSigning.xcconfig.sample`). Make sure to set `DEVELOPER_ACCOUNT_VM_ACCESS = YES`.

`CodeSigning.xcconfig.sample` is a template, not an interactive certificate
picker. Copy it to the ignored `CodeSigning.xcconfig`, enter your team and
profile values, and select an installed signing identity in Xcode when needed.
Never commit private certificates, profiles, or account credentials.

### macOS restore-image testing

The macOS wizard supports restore-image metadata for macOS 12 and newer and
downloads the selected IPSW directly from an Apple CDN. Older catalog entries
may be unavailable, unsigned, or unsupported on the current host even when
their metadata remains visible. After downloading, Lattice VM validates the
archive and hands it to Apple's installation service.

If the installation service cannot open an otherwise complete IPSW, restart
the Mac and retry. On a macOS beta, the matching Xcode device-support package
may be required. Test restore workflows with a correctly entitled build; a
plain command-line helper does not reproduce the app's virtualization access.

Note that due to a macOS bug, you may get a crash when launching a VM with the debugger attached. The workaround is to start Lattice VM with the debugger detached and attach the debugger with Debug -> Attach to Process after launching a VM. Once you do that, you can start additional VMs without any issues with the debugger.

[1]: https://github.com/buusmorten/Lattice-VM/actions?query=workflow%3ABuild
[2]: https://brew.sh
