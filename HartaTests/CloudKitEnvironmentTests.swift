import Foundation
import Testing
@testable import Harta

struct CloudKitEnvironmentTests {
    @Test func readsSignedEnvironmentAndRejectsUnknownValues() throws {
        for value in ["Development", "Production", "Unexpected"] {
            let executable = try executable(environment: value)
            #expect(CloudKitEnvironment.readCodeSignature(in: executable) == CloudKitEnvironment(rawValue: value))
        }
    }

    @Test func rejectsTruncatedSignatures() throws {
        let data = try executable(environment: "Development")
        for length in 0..<data.count {
            #expect(CloudKitEnvironment.readCodeSignature(in: Data(data.prefix(length))) == nil)
        }
    }

    @Test func rejectsInvalidSignatureOffset() throws {
        var data = try executable(environment: "Development")
        data.replaceSubrange(40..<44, with: [0xff, 0xff, 0xff, 0xff])
        #expect(CloudKitEnvironment.readCodeSignature(in: data) == nil)
    }

    private func executable(environment: String) throws -> Data {
        let plist = try PropertyListSerialization.data(
            fromPropertyList: ["com.apple.developer.icloud-container-environment": environment],
            format: .xml, options: 0)
        func words(_ values: [UInt32], bigEndian: Bool = false) -> Data {
            var result = Data()
            for value in values {
                var encoded = bigEndian ? value.bigEndian : value.littleEndian
                withUnsafeBytes(of: &encoded) { result.append(contentsOf: $0) }
            }
            return result
        }
        let signatureLength = UInt32(28 + plist.count)
        var result = words([0xfeedfacf, 0, 0, 2, 1, 16, 0, 0])
        result.append(words([0x1d, 16, 48, signatureLength]))
        result.append(words([0xfade0cc0, signatureLength, 1, 5, 20,
                             0xfade7171, UInt32(plist.count + 8)], bigEndian: true))
        result.append(plist)
        return result
    }
}
