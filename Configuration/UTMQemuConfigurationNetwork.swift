//
// Copyright © 2022 osy. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// Network settings for a single device.
struct UTMQemuConfigurationNetwork: Codable, Identifiable {
    /// Optional user-facing name shared by network tooling and exports.
    var displayName: String?

    /// The last one-click profile applied by the user.
    var profile: NetworkProfile = .custom

    /// Operating mode of this adapter
    var mode: QEMUNetworkMode = .emulated
    
    /// Hardware model to emulate.
    var hardware: any QEMUNetworkDevice = QEMUNetworkDevice_x86_64.e1000
    
    /// Unique MAC address.
    var macAddress: String = UTMQemuConfigurationNetwork.randomMacAddress()
    
    /// If true, will attempt to isolate the host in the guest VLAN.
    var isIsolateFromHost: Bool = false
    
    /// List of forwarded ports.
    var portForward: [UTMQemuConfigurationPortForward] = []
    
    /// In bridged mode this is the physical interface to bridge.
    var bridgeInterface: String?
    
    /// Guest IPv4 for emulated VLAN.
    var vlanGuestAddress: String?
    
    /// Guest IPv6 for emulated VLAN.
    var vlanGuestAddressIPv6: String?
    
    /// Host IPv4 for emulated VLAN.
    var vlanHostAddress: String?
    
    /// Host IPv6 for emulated VLAN.
    var vlanHostAddressIPv6: String?
    
    /// DHCP start address for emulated VLAN.
    var vlanDhcpStartAddress: String?
    
    /// DHCP end address for Apple VLAN
    var vlanDhcpEndAddress: String?
    
    /// DHCP domain for emulated VLAN.
    var vlanDhcpDomain: String?
    
    /// DNS server for emulated VLAN.
    var vlanDnsServerAddress: String?
    
    /// DNS server (IPv6) for emulated VLAN.
    var vlanDnsServerAddressIPv6: String?
    
    /// DNS search domain for emulated VLAN.
    var vlanDnsSearchDomain: String?

    /// Additional ordered DNS search domains. The legacy singular value remains
    /// the first entry for compatibility with older UTM versions.
    var vlanDnsSearchDomains: [String] = []

    /// A local DNS suffix used to describe this virtual network.
    var localDomain: String?
    
    /// Network UUID to attach to in host mode
    var hostNetUuid: String?
    
    /// Can be set to be displayed to the user. Not saved.
    var currentIpAddresses: [String] = []

    let id = UUID()
    
    /// Generate a random MAC address
    /// - Returns: A random MAC address
    static func randomMacAddress() -> String {
        var bytes = (0..<6).map { _ in
            arc4random() % 256
        }
        // byte 0 should be local
        bytes[0] = (bytes[0] & 0xFC) | 0x2
        let string = bytes.reduce("") { partialResult, byte in
            partialResult + String(format: ":%02X", byte)
        }
        return String(string.dropFirst())
    }
    
    enum CodingKeys: String, CodingKey {
        case mode = "Mode"
        case displayName = "DisplayName"
        case profile = "LatticeProfile"
        case hardware = "Hardware"
        case macAddress = "MacAddress"
        case isIsolateFromHost = "IsolateFromHost"
        case portForward = "PortForward"
        case bridgeInterface = "BridgeInterface"
        case vlanGuestAddress = "VlanGuestAddress"
        case vlanGuestAddressIPv6 = "VlanGuestAddressIPv6"
        case vlanHostAddress = "VlanHostAddress"
        case vlanHostAddressIPv6 = "VlanHostAddressIPv6"
        case vlanDhcpStartAddress = "VlanDhcpStartAddress"
        case vlanDhcpEndAddress = "VlanDhcpEndAddress"
        case vlanDhcpDomain = "VlanDhcpDomain"
        case vlanDnsServerAddress = "VlanDnsServerAddress"
        case vlanDnsServerAddressIPv6 = "VlanDnsServerAddressIPv6"
        case vlanDnsSearchDomain = "VlanDnsSearchDomain"
        case vlanDnsSearchDomains = "VlanDnsSearchDomains"
        case localDomain = "LatticeLocalDomain"
        case hostNetUuid = "HostNetUuid"
    }
    
    init() {
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        mode = try values.decode(QEMUNetworkMode.self, forKey: .mode)
        displayName = try values.decodeIfPresent(String.self, forKey: .displayName)
        profile = try values.decodeIfPresent(NetworkProfile.self, forKey: .profile) ?? .custom
        hardware = try values.decode(AnyQEMUConstant.self, forKey: .hardware)
        macAddress = try values.decode(String.self, forKey: .macAddress)
        isIsolateFromHost = try values.decode(Bool.self, forKey: .isIsolateFromHost)
        portForward = try values.decode([UTMQemuConfigurationPortForward].self, forKey: .portForward)
        bridgeInterface = try values.decodeIfPresent(String.self, forKey: .bridgeInterface)
        vlanGuestAddress = try values.decodeIfPresent(String.self, forKey: .vlanGuestAddress)
        vlanGuestAddressIPv6 = try values.decodeIfPresent(String.self, forKey: .vlanGuestAddressIPv6)
        vlanHostAddress = try values.decodeIfPresent(String.self, forKey: .vlanHostAddress)
        vlanHostAddressIPv6 = try values.decodeIfPresent(String.self, forKey: .vlanHostAddressIPv6)
        vlanDhcpStartAddress = try values.decodeIfPresent(String.self, forKey: .vlanDhcpStartAddress)
        vlanDhcpEndAddress = try values.decodeIfPresent(String.self, forKey: .vlanDhcpEndAddress)
        vlanDhcpDomain = try values.decodeIfPresent(String.self, forKey: .vlanDhcpDomain)
        vlanDnsServerAddress = try values.decodeIfPresent(String.self, forKey: .vlanDnsServerAddress)
        vlanDnsServerAddressIPv6 = try values.decodeIfPresent(String.self, forKey: .vlanDnsServerAddressIPv6)
        vlanDnsSearchDomain = try values.decodeIfPresent(String.self, forKey: .vlanDnsSearchDomain)
        vlanDnsSearchDomains = try values.decodeIfPresent([String].self, forKey: .vlanDnsSearchDomains) ?? []
        localDomain = try values.decodeIfPresent(String.self, forKey: .localDomain)
        hostNetUuid = try values.decodeIfPresent(UUID.self, forKey: .hostNetUuid)?.uuidString
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mode, forKey: .mode)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encode(profile, forKey: .profile)
        try container.encode(hardware.asAnyQEMUConstant(), forKey: .hardware)
        try container.encode(macAddress, forKey: .macAddress)
        try container.encode(isIsolateFromHost, forKey: .isIsolateFromHost)
        try container.encode(portForward, forKey: .portForward)
        if mode == .bridged {
            try container.encodeIfPresent(bridgeInterface, forKey: .bridgeInterface)
        }
        try container.encodeIfPresent(vlanGuestAddress, forKey: .vlanGuestAddress)
        try container.encodeIfPresent(vlanGuestAddressIPv6, forKey: .vlanGuestAddressIPv6)
        try container.encodeIfPresent(vlanHostAddress, forKey: .vlanHostAddress)
        try container.encodeIfPresent(vlanHostAddressIPv6, forKey: .vlanHostAddressIPv6)
        try container.encodeIfPresent(vlanDhcpStartAddress, forKey: .vlanDhcpStartAddress)
        try container.encodeIfPresent(vlanDhcpEndAddress, forKey: .vlanDhcpEndAddress)
        try container.encodeIfPresent(vlanDhcpDomain, forKey: .vlanDhcpDomain)
        try container.encodeIfPresent(vlanDnsServerAddress, forKey: .vlanDnsServerAddress)
        try container.encodeIfPresent(vlanDnsServerAddressIPv6, forKey: .vlanDnsServerAddressIPv6)
        try container.encodeIfPresent(vlanDnsSearchDomain, forKey: .vlanDnsSearchDomain)
        if !vlanDnsSearchDomains.isEmpty {
            try container.encode(vlanDnsSearchDomains, forKey: .vlanDnsSearchDomains)
        }
        try container.encodeIfPresent(localDomain, forKey: .localDomain)
        if mode == .host {
            try container.encodeIfPresent(hostNetUuid, forKey: .hostNetUuid)
        }
    }
}

// MARK: - Lattice network intelligence

extension UTMQemuConfigurationNetwork {
    enum NetworkProfile: String, Codable, CaseIterable, Identifiable {
        case custom
        case internetOnly
        case visibleOnLAN
        case development
        case isolatedLab
        case offline

        var id: String { rawValue }

        var title: String {
            switch self {
            case .custom: return NSLocalizedString("Custom", comment: "Network profile")
            case .internetOnly: return NSLocalizedString("Internet Only", comment: "Network profile")
            case .visibleOnLAN: return NSLocalizedString("Visible on LAN", comment: "Network profile")
            case .development: return NSLocalizedString("Development", comment: "Network profile")
            case .isolatedLab: return NSLocalizedString("Isolated Lab", comment: "Network profile")
            case .offline: return NSLocalizedString("Offline", comment: "Network profile")
            }
        }

        var explanation: String {
            switch self {
            case .custom: return NSLocalizedString("Keep the current settings.", comment: "Network profile")
            case .internetOnly: return NSLocalizedString("Internet access through the Mac with no inbound LAN exposure.", comment: "Network profile")
            case .visibleOnLAN: return NSLocalizedString("Appear as a separate device on the physical network.", comment: "Network profile")
            case .development: return NSLocalizedString("Private configurable NAT with host access and port forwarding.", comment: "Network profile")
            case .isolatedLab: return NSLocalizedString("Private lab network with host and internet access blocked.", comment: "Network profile")
            case .offline: return NSLocalizedString("Disconnect this adapter from external networks.", comment: "Network profile")
            }
        }
    }

    enum ValidationSeverity: Int, Comparable {
        case information
        case warning
        case error

        static func < (lhs: ValidationSeverity, rhs: ValidationSeverity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    struct ValidationIssue: Identifiable {
        let id = UUID()
        let severity: ValidationSeverity
        let title: String
        let message: String
    }

    enum DiagnosticState {
        case passed
        case warning
        case unavailable
    }

    struct DiagnosticCheck: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let state: DiagnosticState
    }

    var modeExplanation: String {
        switch mode {
        case .shared:
            return NSLocalizedString("Internet access is shared through the Mac. The VM is normally hidden from the physical LAN.", comment: "Network mode help")
        case .bridged:
            return NSLocalizedString("The VM appears as a separate device on the physical LAN and receives addressing from that network.", comment: "Network mode help")
        case .host:
            return NSLocalizedString("The VM can communicate on a private host network without routed internet access.", comment: "Network mode help")
        case .emulated:
            return NSLocalizedString("QEMU provides a configurable userspace network with DHCP, DNS, and port forwarding.", comment: "Network mode help")
        }
    }

    var topologySummary: String {
        let vm = displayName?.isEmpty == false ? displayName! : NSLocalizedString("VM", comment: "Network topology")
        switch mode {
        case .shared:
            return "\(vm) → \(NSLocalizedString("Shared NAT", comment: "Network topology")) → \(NSLocalizedString("Mac", comment: "Network topology")) → \(NSLocalizedString("Internet", comment: "Network topology"))"
        case .bridged:
            return "\(vm) → \(bridgeInterface ?? NSLocalizedString("Automatic interface", comment: "Network topology")) → \(NSLocalizedString("Physical LAN", comment: "Network topology"))"
        case .host:
            return "\(vm) → \(NSLocalizedString("Host network", comment: "Network topology")) → \(NSLocalizedString("Mac only", comment: "Network topology"))"
        case .emulated:
            let subnet = vlanGuestAddress ?? "10.0.2.0/24"
            return "\(vm) → \(subnet) → \(isIsolateFromHost ? NSLocalizedString("Isolated", comment: "Network topology") : NSLocalizedString("QEMU NAT", comment: "Network topology")) → \(NSLocalizedString("Internet", comment: "Network topology"))"
        }
    }

    var expertArgumentPreview: String {
        let index = 0
        var options: [String]
        switch mode {
        case .shared:
            options = ["vmnet-shared", "id=net\(index)"]
        case .bridged:
            options = ["vmnet-bridged", "id=net\(index)", "ifname=\(bridgeInterface ?? "<automatic>")"]
        case .host:
            options = ["vmnet-host", "id=net\(index)"]
            if let hostNetUuid {
                options.append("net-uuid=\(hostNetUuid)")
            }
        case .emulated:
            options = ["user", "id=net\(index)"]
            if let vlanGuestAddress { options.append("net=\(vlanGuestAddress)") }
            if let vlanHostAddress { options.append("host=\(vlanHostAddress)") }
            if let vlanDhcpStartAddress { options.append("dhcpstart=\(vlanDhcpStartAddress)") }
            if let vlanDnsServerAddress { options.append("dns=\(vlanDnsServerAddress)") }
            for domain in orderedDnsSearchDomains {
                options.append("dnssearch=\(domain)")
            }
            for forward in portForward {
                options.append("hostfwd=\(forward.protocol.rawValue.lowercased()):\(forward.hostAddress ?? ""):\(forward.hostPort)-\(forward.guestAddress ?? ""):\(forward.guestPort)")
            }
        }
        if isIsolateFromHost {
            options.append(mode == .emulated ? "restrict=on" : "isolated=on")
        }
        return "-device \(hardware.rawValue),mac=\(macAddress),netdev=net\(index)\n-netdev \(options.joined(separator: ","))"
    }

    var orderedDnsSearchDomains: [String] {
        var result: [String] = []
        if let vlanDnsSearchDomain, !vlanDnsSearchDomain.isEmpty {
            result.append(vlanDnsSearchDomain)
        }
        result.append(contentsOf: vlanDnsSearchDomains.filter { !$0.isEmpty && !result.contains($0) })
        if let localDomain, !localDomain.isEmpty, !result.contains(localDomain) {
            result.append(localDomain)
        }
        return result
    }

    mutating func apply(profile newProfile: NetworkProfile) {
        profile = newProfile
        switch newProfile {
        case .custom:
            break
        case .internetOnly:
            mode = .shared
            isIsolateFromHost = false
        case .visibleOnLAN:
            mode = .bridged
            isIsolateFromHost = false
        case .development:
            mode = .emulated
            isIsolateFromHost = false
            vlanGuestAddress = vlanGuestAddress ?? "10.0.2.0/24"
            vlanHostAddress = vlanHostAddress ?? "10.0.2.2"
            vlanDhcpStartAddress = vlanDhcpStartAddress ?? "10.0.2.15"
            vlanDnsServerAddress = vlanDnsServerAddress ?? "10.0.2.3"
            localDomain = localDomain ?? "dev.lattice"
        case .isolatedLab:
            mode = .emulated
            isIsolateFromHost = true
            vlanGuestAddress = vlanGuestAddress ?? "10.77.0.0/24"
            vlanDhcpStartAddress = vlanDhcpStartAddress ?? "10.77.0.15"
            localDomain = localDomain ?? "lab.lattice"
            portForward.removeAll()
        case .offline:
            mode = .emulated
            isIsolateFromHost = true
            portForward.removeAll()
        }
    }

    var validationIssues: [ValidationIssue] {
        var issues: [ValidationIssue] = []
        if !Self.isValidMacAddress(macAddress) {
            issues.append(.init(severity: .error,
                                title: NSLocalizedString("Invalid MAC address", comment: "Network validation"),
                                message: NSLocalizedString("Use six hexadecimal octets separated by colons.", comment: "Network validation")))
        }
        if mode == .bridged && bridgeInterface == nil {
            issues.append(.init(severity: .information,
                                title: NSLocalizedString("Automatic bridge interface", comment: "Network validation"),
                                message: NSLocalizedString("The first available interface will be selected. Wi-Fi bridging can be limited by the access point.", comment: "Network validation")))
        }
        if mode == .emulated, let subnet = vlanGuestAddress, Self.ipv4Network(subnet) == nil {
            issues.append(.init(severity: .error,
                                title: NSLocalizedString("Invalid guest subnet", comment: "Network validation"),
                                message: NSLocalizedString("Enter an IPv4 network in CIDR notation, for example 10.0.2.0/24.", comment: "Network validation")))
        }
        if let subnetText = vlanGuestAddress, let subnet = Self.ipv4Network(subnetText) {
            let addresses = [
                ("Host address", vlanHostAddress),
                ("DHCP start", vlanDhcpStartAddress),
                ("DHCP end", vlanDhcpEndAddress),
                ("DNS server", vlanDnsServerAddress)
            ]
            for (label, value) in addresses {
                if let value, let address = Self.ipv4Address(value), !subnet.contains(address) {
                    issues.append(.init(severity: .error,
                                        title: NSLocalizedString("Address outside guest subnet", comment: "Network validation"),
                                        message: "\(label) \(value) \(NSLocalizedString("is not inside", comment: "Network validation")) \(subnetText)."))
                }
            }
            if let startText = vlanDhcpStartAddress,
               let endText = vlanDhcpEndAddress,
               let start = Self.ipv4Address(startText),
               let end = Self.ipv4Address(endText),
               start > end {
                issues.append(.init(severity: .error,
                                    title: NSLocalizedString("Invalid DHCP range", comment: "Network validation"),
                                    message: NSLocalizedString("The DHCP start address must not be greater than the end address.", comment: "Network validation")))
            }
            if let host = vlanHostAddress, host == vlanDhcpStartAddress || host == vlanDhcpEndAddress {
                issues.append(.init(severity: .error,
                                    title: NSLocalizedString("Gateway collision", comment: "Network validation"),
                                    message: NSLocalizedString("The host address cannot be an endpoint of the DHCP range.", comment: "Network validation")))
            }
        }
        let groups = Dictionary(grouping: portForward, by: { "\($0.protocol.rawValue):\($0.hostAddress ?? "0.0.0.0"):\($0.hostPort)" })
        for duplicate in groups.values where duplicate.count > 1 {
            if let forward = duplicate.first {
                issues.append(.init(severity: .error,
                                    title: NSLocalizedString("Port-forward collision", comment: "Network validation"),
                                    message: "\(forward.protocol.prettyValue) \(forward.hostAddress ?? "0.0.0.0"):\(forward.hostPort) \(NSLocalizedString("is used more than once.", comment: "Network validation"))"))
            }
        }
        for forward in portForward where forward.isExposedToLAN {
            issues.append(.init(severity: .warning,
                                title: NSLocalizedString("Service exposed to the LAN", comment: "Network validation"),
                                message: "\(forward.protocol.prettyValue) \(forward.hostPort) \(NSLocalizedString("listens on every host interface. Use 127.0.0.1 for host-only access.", comment: "Network validation"))"))
        }
        return issues.sorted { $0.severity > $1.severity }
    }

    var preflightDiagnostics: [DiagnosticCheck] {
        var checks: [DiagnosticCheck] = [
            .init(title: NSLocalizedString("Virtual adapter configured", comment: "Network diagnostic"),
                  detail: "\(hardware.prettyValue) · \(macAddress)",
                  state: Self.isValidMacAddress(macAddress) ? .passed : .warning)
        ]
        if mode == .emulated {
            checks.append(.init(title: NSLocalizedString("DHCP service", comment: "Network diagnostic"),
                                detail: vlanDhcpStartAddress.map { "\(NSLocalizedString("Starts at", comment: "Network diagnostic")) \($0)" } ?? NSLocalizedString("Uses the QEMU default range", comment: "Network diagnostic"),
                                state: .passed))
        } else if mode == .host && hostNetUuid != nil {
            checks.append(.init(title: NSLocalizedString("DHCP service", comment: "Network diagnostic"),
                                detail: NSLocalizedString("Not provided on reusable host networks; configure the guest manually.", comment: "Network diagnostic"),
                                state: .warning))
        } else {
            checks.append(.init(title: NSLocalizedString("DHCP service", comment: "Network diagnostic"),
                                detail: NSLocalizedString("Provided by macOS or the physical LAN.", comment: "Network diagnostic"),
                                state: .passed))
        }
        checks.append(.init(title: NSLocalizedString("Guest address detected", comment: "Network diagnostic"),
                            detail: currentIpAddresses.isEmpty ? NSLocalizedString("Available after the VM starts and reports an address.", comment: "Network diagnostic") : currentIpAddresses.joined(separator: ", "),
                            state: currentIpAddresses.isEmpty ? .unavailable : .passed))
        checks.append(.init(title: NSLocalizedString("DNS configuration", comment: "Network diagnostic"),
                            detail: mode == .emulated ? (vlanDnsServerAddress ?? NSLocalizedString("QEMU default DNS proxy", comment: "Network diagnostic")) : NSLocalizedString("Inherited from macOS or the physical LAN", comment: "Network diagnostic"),
                            state: .passed))
        checks.append(.init(title: NSLocalizedString("Host and internet reachability", comment: "Network diagnostic"),
                            detail: NSLocalizedString("Runtime probe available after the VM starts.", comment: "Network diagnostic"),
                            state: .unavailable))
        if !portForward.isEmpty {
            checks.append(.init(title: NSLocalizedString("Port-forward rules", comment: "Network diagnostic"),
                                detail: validationIssues.contains(where: { $0.title == NSLocalizedString("Port-forward collision", comment: "Network validation") })
                                    ? NSLocalizedString("Resolve collisions before starting the VM.", comment: "Network diagnostic")
                                    : "\(portForward.count) \(NSLocalizedString("rule(s) ready", comment: "Network diagnostic"))",
                                state: validationIssues.contains(where: { $0.severity == .error }) ? .warning : .passed))
        }
        return checks
    }

    private static func isValidMacAddress(_ value: String) -> Bool {
        value.range(of: #"^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$"#, options: .regularExpression) != nil
    }

    private static func ipv4Address(_ text: String) -> UInt32? {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return nil }
        var result: UInt32 = 0
        for part in parts {
            guard let octet = UInt8(part) else { return nil }
            result = (result << 8) | UInt32(octet)
        }
        return result
    }

    private static func ipv4Network(_ text: String) -> (network: UInt32, mask: UInt32, contains: (UInt32) -> Bool)? {
        let components = text.split(separator: "/", omittingEmptySubsequences: false)
        guard components.count == 2,
              let address = ipv4Address(String(components[0])),
              let prefix = UInt32(components[1]),
              prefix <= 32 else { return nil }
        let mask: UInt32 = prefix == 0 ? 0 : UInt32.max << (32 - prefix)
        let network = address & mask
        return (network, mask, { candidate in candidate & mask == network })
    }
}

// MARK: - Default construction

extension UTMQemuConfigurationNetwork {
    init?(forArchitecture architecture: QEMUArchitecture, target: any QEMUTarget) {
        self.init()
        let rawTarget = target.rawValue
        if rawTarget.hasPrefix("pc") {
            if architecture == .i386 {
                hardware = QEMUNetworkDevice_i386.ne2k_isa
            } else {
                hardware = QEMUNetworkDevice_x86_64.rtl8139
            }
        } else if rawTarget.hasPrefix("q35") {
            hardware = QEMUNetworkDevice_x86_64.e1000
        } else if rawTarget == "isapc" {
            hardware = QEMUNetworkDevice_x86_64.ne2k_isa
        } else if rawTarget.hasPrefix("virt-") || rawTarget == "virt" {
            hardware = QEMUNetworkDevice_aarch64.virtio_net_pci
        } else if [.ppc, .ppc64].contains(architecture) && rawTarget == QEMUTarget_ppc.mac99.rawValue {
            hardware = QEMUNetworkDevice_ppc.sungem
        } else if architecture == .m68k && rawTarget == QEMUTarget_m68k.q800.rawValue {
            hardware = QEMUNetworkDevice_m68k.dp8393x
        } else {
            let cards = architecture.networkDeviceType.allRawValues
            if let first = cards.first {
                hardware = AnyQEMUConstant(rawValue: first)!
            } else {
                return nil
            }
        }
        #if os(macOS)
        mode = .shared
        #else
        mode = .emulated
        #endif
    }
}

// MARK: - Conversion of old config format

extension UTMQemuConfigurationNetwork {
    init?(migrating oldConfig: UTMLegacyQemuConfiguration) {
        self.init()
        guard oldConfig.networkEnabled else {
            return nil
        }
        guard let oldMode = convertMode(from: oldConfig.networkMode) else {
            return nil
        }
        mode = oldMode
        if let hardwareStr = oldConfig.networkCard {
            hardware = AnyQEMUConstant(rawValue: hardwareStr)!
        }
        if let macString = oldConfig.networkCardMac {
            macAddress = macString
        }
        isIsolateFromHost = oldConfig.networkIsolate
        bridgeInterface = oldConfig.networkBridgeInterface
        vlanGuestAddress = oldConfig.networkAddress
        vlanGuestAddressIPv6 = oldConfig.networkAddressIPv6
        vlanHostAddress = oldConfig.networkHost
        vlanHostAddressIPv6 = oldConfig.networkHostIPv6
        vlanDhcpStartAddress = oldConfig.networkDhcpStart
        vlanDhcpDomain = oldConfig.networkDhcpDomain
        vlanDnsServerAddress = oldConfig.networkDnsServer
        vlanDnsServerAddressIPv6 = oldConfig.networkDnsServerIPv6
        vlanDnsSearchDomain = oldConfig.networkDnsSearch
        for i in 0..<oldConfig.countPortForwards {
            let oldPortForward = oldConfig.portForward(for: i)!
            portForward.append(UTMQemuConfigurationPortForward(migrating: oldPortForward))
        }
    }
    
    private func convertMode(from str: String?) -> QEMUNetworkMode? {
        if str == "emulated" {
            return .emulated
        } else if str == "shared" {
            return .shared
        } else if str == "host" {
            return .host
        } else if str == "bridged" {
            return .bridged
        } else {
            return nil
        }
    }
}
