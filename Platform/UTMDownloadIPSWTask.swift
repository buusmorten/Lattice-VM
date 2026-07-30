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
import Virtualization

/// A catalog of macOS restore images for Apple's virtual Mac device.
///
/// The catalog service supplies metadata only. Download URLs are accepted only
/// when they point directly to an Apple-controlled HTTPS CDN.
@available(iOS, unavailable, message: "Apple Virtualization not available on iOS")
@available(macOS 12, *)
enum MacOSRestoreImageCatalog {
    struct Entry: Decodable, Identifiable, Hashable {
        let version: String
        let buildID: String
        let fileSize: Int64
        let url: URL

        var id: URL { url }

        var title: String {
            let size = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            return "macOS \(version) (\(buildID)) · \(size)"
        }

        var platformVersion: Int {
            buildID.integerPrefix() ?? 0
        }

        var majorVersion: Int {
            version.integerPrefix() ?? 0
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case buildID = "buildid"
            case fileSize = "filesize"
            case url
        }
    }

    private struct Response: Decodable {
        let firmwares: [Entry]
    }

    private static let catalogURL = URL(string: "https://api.ipsw.me/v4/device/VirtualMac2,1?type=ipsw")!

    static func fetch() async throws -> [Entry] {
        let (data, response) = try await URLSession.shared.data(from: catalogURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let entries = try JSONDecoder().decode(Response.self, from: data).firmwares
        return entries
            .filter { entry in
                (entry.version.integerPrefix() ?? 0) >= 12 && isAppleCDN(entry.url)
            }
            .sorted {
                $0.version.compare($1.version, options: .numeric) == .orderedDescending
            }
    }

    private static func isAppleCDN(_ url: URL) -> Bool {
        guard url.scheme == "https", let host = url.host?.lowercased() else {
            return false
        }
        return host == "apple.com" ||
            host.hasSuffix(".apple.com") ||
            host == "cdn-apple.com" ||
            host.hasSuffix(".cdn-apple.com")
    }
}

/// Downloads an IPSW from the web and adds it to the VM.
@available(iOS, unavailable, message: "Apple Virtualization not available on iOS")
@available(macOS 12, *)
class UTMDownloadIPSWTask: UTMDownloadTask {
    let config: UTMAppleConfiguration
    
    private var cacheUrl: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    @MainActor init(for config: UTMAppleConfiguration) {
        self.config = config
        super.init(for: config.system.boot.macRecoveryIpswURL!, named: config.information.name)
    }
    
    override func processCompletedDownload(at location: URL, response: URLResponse?) async throws -> any UTMVirtualMachine {
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw NSLocalizedString("Apple's download server returned an invalid response. Please try the download again.", comment: "UTMDownloadIPSWTask")
        }

        if !fileManager.fileExists(atPath: cacheUrl.path) {
            try fileManager.createDirectory(at: cacheUrl, withIntermediateDirectories: false)
        }
        
        let cacheIpsw = cacheUrl.appendingPathComponent(url.lastPathComponent)
        if fileManager.fileExists(atPath: cacheIpsw.path) {
            try fileManager.removeItem(at: cacheIpsw)
        }
        try fileManager.moveItem(at: location, to: cacheIpsw)

        // URLSession creates downloads with owner-only permissions and may attach
        // quarantine metadata. The macOS restore service runs out of process and
        // must be able to open the completed IPSW after the download delegate exits.
        try fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: cacheIpsw.path)
        try? fileManager.removeExtendedAttribute(named: "com.apple.quarantine", at: cacheIpsw)

        guard isIPSW(at: cacheIpsw) else {
            try? fileManager.removeItem(at: cacheIpsw)
            throw NSLocalizedString("The downloaded restore image is incomplete or is not a valid IPSW. Please download it again.", comment: "UTMDownloadIPSWTask")
        }

        let restoreImage: VZMacOSRestoreImage
        do {
            restoreImage = try await VZMacOSRestoreImage.image(from: cacheIpsw)
        } catch {
            let cocoaError = error as NSError
            if cocoaError.domain == VZErrorDomain {
                throw NSLocalizedString("macOS downloaded successfully, but Apple's installation service could not open the restore image. Restart your Mac and try again. If you are running a macOS beta, install the matching Xcode device-support package first.", comment: "UTMDownloadIPSWTask")
            }
            throw error
        }
        guard let hardwareModel = restoreImage.mostFeaturefulSupportedConfiguration?.hardwareModel else {
            throw NSLocalizedString("This Mac cannot run the selected macOS restore image.", comment: "UTMDownloadIPSWTask")
        }
        await MainActor.run {
            config.system.boot.macRecoveryIpswURL = cacheIpsw
            config.system.macPlatform = UTMAppleConfigurationMacPlatform(newHardware: hardwareModel)
        }
        return try UTMAppleVirtualMachine(newForConfiguration: config, destinationUrl: UTMData.defaultStorageUrl)
    }

    private func isIPSW(at url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return false
        }
        defer {
            try? handle.close()
        }
        return (try? handle.read(upToCount: 4)) == Data([0x50, 0x4B, 0x03, 0x04])
    }
}

private extension FileManager {
    func removeExtendedAttribute(named name: String, at url: URL) throws {
        if removexattr(url.path, name, 0) != 0 && errno != ENOATTR {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
    }
}
