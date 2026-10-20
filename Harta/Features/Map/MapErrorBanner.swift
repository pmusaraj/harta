import SwiftUI

struct MapErrorBanner: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Label(message, systemImage: "wifi.exclamationmark")
            Button("Try again", action: retry)
        }
        .font(.callout)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }
}
