//
// Copyright © 2020 osy. All rights reserved.
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
#if os(macOS)
import Virtualization
#endif

struct VMConfigNetworkView: View {
    @AppStorage("HostNetworks") var hostNetworksData: Data = Data()
    @Binding var config: UTMQemuConfigurationNetwork
    @Binding var system: UTMQemuConfigurationSystem
    @State private var hostNetworks: [UTMConfigurationHostNetwork] = []
    @State private var showAdvanced: Bool = false
    @State private var selectedProfile: UTMQemuConfigurationNetwork.NetworkProfile = .custom
    @State private var showExpertPreview: Bool = false
    
    private func loadData() {
        hostNetworks = (try? PropertyListDecoder().decode([UTMConfigurationHostNetwork].self, from: hostNetworksData)) ?? []
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Network Profile")) {
                    Picker("Profile", selection: $selectedProfile) {
                        ForEach(UTMQemuConfigurationNetwork.NetworkProfile.allCases) { profile in
                            Text(profile.title).tag(profile)
                        }
                    }
                    Text(selectedProfile.explanation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Apply Profile") {
                        config.apply(profile: selectedProfile)
                    }
                    .disabled(selectedProfile == .custom)
                }

                Section(header: Text("Topology")) {
                    Text(config.topologySummary)
                        .font(.system(.body, design: .monospaced))
                    Text(config.modeExplanation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let subnet = config.vlanGuestAddress, config.mode == .emulated {
                        HStack {
                            Text("Guest subnet")
                            Spacer()
                            Text(subnet).foregroundColor(.secondary)
                        }
                    }
                    if let gateway = config.vlanHostAddress, config.mode == .emulated {
                        HStack {
                            Text("Gateway")
                            Spacer()
                            Text(gateway).foregroundColor(.secondary)
                        }
                    }
                    if let start = config.vlanDhcpStartAddress, config.mode == .emulated {
                        HStack {
                            Text("DHCP starts")
                            Spacer()
                            Text(start).foregroundColor(.secondary)
                        }
                    }
                    if let dns = config.vlanDnsServerAddress, config.mode == .emulated {
                        HStack {
                            Text("DNS source")
                            Spacer()
                            Text("QEMU DHCP · \(dns)").foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Text("DNS source")
                            Spacer()
                            Text(config.mode == .bridged ? "Physical LAN" : "macOS").foregroundColor(.secondary)
                        }
                    }
                }

                if !config.validationIssues.isEmpty {
                    Section(header: Text("Safety Check")) {
                        ForEach(config.validationIssues) { issue in
                            HStack(alignment: .top) {
                                Image(systemName: issue.severity == .error ? "xmark.octagon.fill" : issue.severity == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                    .foregroundColor(issue.severity == .error ? .red : issue.severity == .warning ? .orange : .blue)
                                VStack(alignment: .leading) {
                                    Text(issue.title).font(.headline)
                                    Text(issue.message).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Network Diagnostics")) {
                    ForEach(config.preflightDiagnostics) { check in
                        HStack(alignment: .top) {
                            Image(systemName: check.state == .passed ? "checkmark.circle.fill" : check.state == .warning ? "exclamationmark.triangle.fill" : "clock.fill")
                                .foregroundColor(check.state == .passed ? .green : check.state == .warning ? .orange : .secondary)
                            VStack(alignment: .leading) {
                                Text(check.title)
                                Text(check.detail).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    Text("Configuration checks run now. Live host, DNS, internet, and service probes require a running guest.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Hardware")) {
                    #if os(macOS)
                    VMConfigConstantPicker("Network Mode", selection: $config.mode)
                    if config.mode == .bridged {
                        Picker("Bridged Interface", selection: $config.bridgeInterface) {
                            Text("Automatic")
                                .tag(nil as String?)
                            ForEach(VZBridgedNetworkInterface.networkInterfaces, id: \.identifier) { interface in
                                Text(interface.localizedDisplayName.map { "\($0) (\(interface.identifier))" } ?? interface.identifier)
                                    .tag(interface.identifier as String?)
                            }
                        }
                        Text("Wi-Fi bridges can be limited by the access point and may not pass every protocol. Ethernet is preferred for reliable layer-2 access.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if config.mode == .host {
                        Picker("Host Network", selection: $config.hostNetUuid) {
                            Text("Default (private)")
                                .tag(nil as String?)
                            ForEach(hostNetworks) { interface in
                                Text(interface.name)
                                    .tag(interface.uuid as String?)
                            }
                        }.help("You can configure additional host networks in Lattice VM Settings.")
                        if config.hostNetUuid != nil {
                            Text("Note: No DHCP will be provided by Lattice VM")
                        }
                    }
                    #endif
                    VMConfigConstantPicker("Emulated Network Card", selection: $config.hardware, type: system.architecture.networkDeviceType)
                }.onAppear(perform: loadData)
                
                HStack {
                    DefaultTextField("MAC Address", text: $config.macAddress, prompt: "00:00:00:00:00:00")
                    Button("Random") {
                        config.macAddress = UTMQemuConfigurationNetwork.randomMacAddress()
                    }
                }

                Toggle(isOn: $showAdvanced.animation(), label: {
                    Text("Show Advanced Settings")
                })

                if showAdvanced {
                    Section(header: Text("IP Configuration")) {
                        IPConfigurationSection(config: $config).multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("Safe Expert Mode")) {
                    Toggle("Show generated QEMU network arguments", isOn: $showExpertPreview)
                    if showExpertPreview {
                        Text(config.expertArgumentPreview)
                            .font(.system(.caption, design: .monospaced))
                        Text("Preview only. Lattice VM still validates and generates the final command when the VM starts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                #if os(macOS)
                /// Bridged and shared networking doesn't support port forwarding
                if #unavailable(macOS 12), config.mode == .emulated {
                    VMConfigNetworkPortForwardLegacyView(config: $config)
                }
                #else
                VMConfigNetworkPortForwardView(config: $config)
                #endif
            }.onAppear {
                selectedProfile = config.profile
            }
        }
    }
}

struct VMConfigNetworkingView_Previews: PreviewProvider {
    @State static private var config = UTMQemuConfigurationNetwork()
    @State static private var system = UTMQemuConfigurationSystem()
    
    static var previews: some View {
        VMConfigNetworkView(config: $config, system: $system)
    }
}
