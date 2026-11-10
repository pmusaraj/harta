import Foundation

/// Reads the entitlement from the installed executable, including after distribution re-signing.
/// This is informational only; CloudKit remains responsible for selecting its environment.
enum CloudKitEnvironment: String {
    case development = "Development"
    case production = "Production"

    static let current: Self? = {
        #if targetEnvironment(simulator)
        // CloudKit supports only the development environment in Simulator.
        return .development
        #else
        guard let url = Bundle.main.executableURL,
              let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        return readCodeSignature(in: data)
        #endif
    }()

    static func readCodeSignature(in data: Data) -> Self? {
        func word(_ offset: Int, bigEndian: Bool = false) -> Int? {
            guard offset >= 0, offset <= data.count - 4 else { return nil }
            let bytes = data[offset..<(offset + 4)]
            return (bigEndian ? Array(bytes) : Array(bytes.reversed()))
                .reduce(0) { ($0 << 8) | Int($1) }
        }

        // Installed iOS executables are thin, little-endian, 64-bit Mach-O files.
        guard word(0) == 0xfeedfacf,
              let commandCount = word(16), let commandBytes = word(20),
              commandBytes <= data.count - 32, commandCount <= commandBytes / 8 else { return nil }
        let commandsEnd = 32 + commandBytes
        var command = 32
        for _ in 0..<commandCount {
            guard command <= commandsEnd - 8,
                  let size = word(command + 4), size >= 8,
                  size <= commandsEnd - command else { return nil }
            defer { command += size }
            guard word(command) == 0x1d else { continue } // LC_CODE_SIGNATURE
            guard size >= 16, let start = word(command + 8), let size = word(command + 12),
                  start <= data.count, size <= data.count - start, size >= 12,
                  word(start, bigEndian: true) == 0xfade0cc0,
                  let length = word(start + 4, bigEndian: true), length >= 12, length <= size,
                  let count = word(start + 8, bigEndian: true), count <= (length - 12) / 8 else { return nil }
            for index in 0..<count {
                let entry = start + 12 + index * 8
                guard word(entry, bigEndian: true) == 5 else { continue } // CSSLOT_ENTITLEMENTS
                guard let offset = word(entry + 4, bigEndian: true), offset <= length - 8,
                      word(start + offset, bigEndian: true) == 0xfade7171,
                      let blobLength = word(start + offset + 4, bigEndian: true),
                      blobLength >= 8, blobLength <= length - offset else { return nil }
                let payload = data.subdata(in: (start + offset + 8)..<(start + offset + blobLength))
                guard let plist = try? PropertyListSerialization.propertyList(from: payload, format: nil),
                      let entitlements = plist as? [String: Any],
                      let value = entitlements["com.apple.developer.icloud-container-environment"] as? String else { return nil }
                return Self(rawValue: value)
            }
            return nil
        }
        return nil
    }
}
