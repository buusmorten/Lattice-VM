//
// Copyright © 2021 osy. All rights reserved.
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

import SwiftUI
import Virtualization

struct VMConfigAppleNetworkingView: View {
    @Binding var config: UTMAppleConfigurationNetwork
    @EnvironmentObject private var data: UTMData
    @State private var newMacAddress: String?
    
    var body: some View {
        Form {
            Section(header: Text("Topology")) {
                Text(config.mode == .shared ? "VM → Apple NAT → Mac → Internet" : "VM → Physical Interface → LAN")
                    .font(.system(.body, design: .monospaced))
                Text(config.mode == .shared
                     ? "Internet access is shared through macOS. The VM is normally hidden from the physical LAN."
                     : "The VM appears as a separate device on the physical LAN and receives addressing from that network.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            VMConfigConstantPicker("Network Mode", selection: $config.mode)
            HStack {
                TextField("MAC Address", text: $newMacAddress.bound, onCommit: {
                    commitMacAddress()
                })
                .onAppear {
                    newMacAddress = config.macAddress
                }
                Button("Random") {
                    let random = VZMACAddress.randomLocallyAdministered().string
                    newMacAddress = random
                    commitMacAddress()
                }
            }
            if config.mode == .bridged {
                Section(header: Text("Bridged Settings")) {
                    Picker("Interface", selection: $config.bridgeInterface) {
                        Text("Automatic")
                            .tag(nil as String?)
                        ForEach(VZBridgedNetworkInterface.networkInterfaces, id: \.identifier) { interface in
                            Text(interface.localizedDisplayName.map { "\($0) (\(interface.identifier))" } ?? interface.identifier)
                                .tag(interface.identifier as String?)
                        }
                    }
                    Text("Wi-Fi bridging can be limited by the access point and may not pass every layer-2 protocol. Ethernet is preferred.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Section(header: Text("Apple Virtualization Limitations")) {
                Label("Custom DHCP, DNS, port forwarding, packet capture, firewall rules, and network shaping require the QEMU backend.", systemImage: "info.circle")
                    .font(.caption)
                Text("Configure static guest addresses and DNS inside the guest when using Apple Virtualization.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func commitMacAddress() {
        guard let macAddress = newMacAddress else {
            return
        }
        if let _ = VZMACAddress(string: macAddress) {
            config.macAddress = macAddress
        } else {
            data.busyWork {
                throw NSLocalizedString("Invalid MAC address.", comment: "VMConfigAppleNetworkingView")
            }
        }
    }
}

struct VMConfigAppleNetworkingView_Previews: PreviewProvider {
    @State static private var config = UTMAppleConfigurationNetwork()
    
    static var previews: some View {
        VMConfigAppleNetworkingView(config: $config)
    }
}
