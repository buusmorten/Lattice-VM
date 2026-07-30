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

@available(macOS 12, *)
struct VMWizardOSMacView: View {
    @ObservedObject var wizardState: VMWizardState
    @State private var isFileImporterPresented = false
    @State private var restoreImages: [MacOSRestoreImageCatalog.Entry] = []
    @State private var selectedRestoreImageID = "latest"
    @State private var selectedMajorVersion = 0
    @State private var latestRestoreImageURL: URL?
    @State private var isLoadingRestoreImages = false
    @State private var catalogError: String?

    var body: some View {
        VMWizardContent("macOS") {
            Section {
                Text("Choose macOS 12 or newer. Lattice VM downloads the selected restore image directly from Apple's CDN and continues installation automatically.")

                #if arch(arm64)
                Picker("macOS Version", selection: $selectedMajorVersion) {
                    Text("Latest supported by this Mac")
                        .tag(0)
                    ForEach(availableMajorVersions, id: \.self) { version in
                        Text("macOS \(version)")
                            .tag(version)
                    }
                }
                .disabled(isLoadingRestoreImages || restoreImages.isEmpty)
                .onChange(of: selectedMajorVersion) { newValue in
                    if newValue == 0 {
                        selectedRestoreImageID = "latest"
                        wizardState.macRecoveryIpswURL = latestRestoreImageURL
                    } else if let newest = restoreImages.first(where: { $0.majorVersion == newValue }) {
                        select(newest)
                    }
                }

                if selectedMajorVersion != 0 {
                    Picker("Release", selection: $selectedRestoreImageID) {
                        ForEach(restoreImages.filter { $0.majorVersion == selectedMajorVersion }) { image in
                            Text(image.title)
                                .tag(image.url.absoluteString)
                        }
                    }
                    .onChange(of: selectedRestoreImageID) { newValue in
                        guard let image = restoreImages.first(where: { $0.url.absoluteString == newValue }) else {
                            return
                        }
                        apply(image)
                    }
                } else {
                    Picker("Release", selection: $selectedRestoreImageID) {
                        Text("Latest supported by this Mac")
                            .tag("latest")
                    }
                    .disabled(true)
                }

                if let selected = restoreImages.first(where: { $0.url.absoluteString == selectedRestoreImageID }) {
                    HStack {
                        Text("Selected")
                        Spacer()
                        Text(selected.title)
                            .foregroundColor(.secondary)
                    }
                }

                if isLoadingRestoreImages {
                    HStack {
                        ProgressView()
                        Text("Loading available macOS versions…")
                            .foregroundColor(.secondary)
                    }
                } else if let catalogError {
                    Text(catalogError)
                        .font(.caption)
                        .foregroundColor(.orange)
                    Button("Try Again") {
                        loadRestoreImages()
                    }
                } else {
                    Text("Version metadata is provided by IPSW Downloads. Restore images are downloaded only from Apple-controlled HTTPS servers.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                #endif

                Spacer()

                Text("Or import an existing IPSW").foregroundColor(.secondary)
                Spacer()

                #if arch(arm64)
                if let selected = wizardState.macRecoveryIpswURL {
                    Text(selected.lastPathComponent)
                        .font(.caption)
                }
                FileBrowseField(url: $wizardState.macRecoveryIpswURL, isFileImporterPresented: $isFileImporterPresented)
                #endif
                if wizardState.isBusy {
                    Spinner(size: .large)
                }
                Spacer()
            } header: {
                Text("Import IPSW")
            }
        }
        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.ipsw], onCompletion: processIpsw)
        .onDrop(of: [.fileURL], delegate: self)
        .onAppear {
            wizardState.bootDevice = .none
            latestRestoreImageURL = wizardState.macRecoveryIpswURL
            loadRestoreImages()
        }
    }

    private func loadRestoreImages() {
        guard !isLoadingRestoreImages else {
            return
        }
        isLoadingRestoreImages = true
        catalogError = nil
        Task {
            do {
                let images = try await MacOSRestoreImageCatalog.fetch()
                await MainActor.run {
                    restoreImages = images
                    if let current = wizardState.macRecoveryIpswURL,
                       let selected = images.first(where: { $0.url == current }) {
                        selectedMajorVersion = selected.majorVersion
                        selectedRestoreImageID = selected.url.absoluteString
                    }
                    isLoadingRestoreImages = false
                }
            } catch {
                await MainActor.run {
                    catalogError = NSLocalizedString("Could not load the macOS version catalog. You can still use the latest supported version or import an IPSW.", comment: "VMWizardOSMacView")
                    isLoadingRestoreImages = false
                }
            }
        }
    }

    private var availableMajorVersions: [Int] {
        Array(Set(restoreImages.map(\.majorVersion))).sorted(by: >)
    }

    private func select(_ image: MacOSRestoreImageCatalog.Entry) {
        selectedRestoreImageID = image.url.absoluteString
        apply(image)
    }

    private func apply(_ image: MacOSRestoreImageCatalog.Entry) {
        wizardState.macRecoveryIpswURL = image.url
        wizardState.macPlatformVersion = image.platformVersion
        wizardState.bootImageURL = nil
    }
    
    private func processIpsw(_ result: Result<URL, Error>) {
        wizardState.busyWorkAsync {
            #if arch(arm64)
            let url = try result.get()
            let scopedAccess = url.startAccessingSecurityScopedResource()
            defer {
                if scopedAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let image = try await VZMacOSRestoreImage.image(from: url)
            guard let model = image.mostFeaturefulSupportedConfiguration?.hardwareModel else {
                throw NSLocalizedString("Your machine does not support running this IPSW.", comment: "VMWizardOSMacView")
            }
            await MainActor.run {
                wizardState.macPlatform = UTMAppleConfigurationMacPlatform(newHardware: model)
                wizardState.macRecoveryIpswURL = url
                wizardState.macPlatformVersion = image.buildVersion.integerPrefix()
                wizardState.bootImageURL = nil
                wizardState.next()
            }
            #else
            throw NSLocalizedString("macOS guests are only supported on ARM64 devices.", comment: "VMWizardOSMacView")
            #endif
        }
    }
}

@available(macOS 12, *)
extension VMWizardOSMacView: DropDelegate {

    func validateDrop(info: DropInfo) -> Bool {
        urlFrom(info: info) != nil
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let url = urlFrom(info: info) else { return false }

        processIpsw(.success(url))
        return true
    }

    private func urlFrom(info: DropInfo) -> URL? {
        let providers = info.itemProviders(for: [.fileURL])
        guard providers.count == 1,
              let first = providers.first
            else { return nil }

        var validURL: URL?

        let group = DispatchGroup()
        group.enter()

        _ = first.loadObject(ofClass: URL.self) { url, _ in
            if url?.pathExtension == "ipsw" {
                validURL = url
            }
            group.leave()
        }

        group.wait()

        return validURL
    }
}

@available(macOS 12, *)
struct VMWizardOSMacView_Previews: PreviewProvider {
    @StateObject static var wizardState = VMWizardState()
    
    static var previews: some View {
        VMWizardOSMacView(wizardState: wizardState)
    }
}
