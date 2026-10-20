import SwiftUI

struct MapStyleLicensesView: View {
    private let licenses: String = ["OpenFreeMapStylesLicense", "PositronLicense", "DarkMatterLicense"]
        .compactMap { name in
            Bundle.main.url(forResource: name, withExtension: "txt")
                .flatMap { try? String(contentsOf: $0, encoding: .utf8) }
        }
        .joined(separator: "\n\n")

    var body: some View {
        ScrollView {
            Text(licenses)
                .font(.footnote)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle("Map style licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}
