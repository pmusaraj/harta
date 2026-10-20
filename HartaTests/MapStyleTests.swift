import Foundation
import Testing
@testable import Harta

struct MapStyleTests {
    @Test func bundledStylesHaveValidSourcesAndUniqueLayers() throws {
        for style in MapStyle.allCases {
            for isDark in [false, true] {
                let data = try Data(contentsOf: style.url(isDark: isDark))
                let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
                let sources = try #require(json["sources"] as? [String: Any])
                let layers = try #require(json["layers"] as? [[String: Any]])
                let identifiers = layers.compactMap { $0["id"] as? String }
                #expect(json["version"] as? Int == 8)
                #expect(!layers.isEmpty)
                #expect(Set(identifiers).count == layers.count)
                for layer in layers {
                    if let source = layer["source"] as? String { #expect(sources[source] != nil) }
                }
            }
        }
    }

    @Test func optionalLayersExistAndStartHiddenInEveryStyle() throws {
        for style in MapStyle.allCases {
            for dark in [false, true] {
                let data = try Data(contentsOf: style.url(isDark: dark))
                let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
                let layers = try #require(json["layers"] as? [[String: Any]])
                for overlay in MapOverlay.allCases {
                    let layer = try #require(layers.first { $0["id"] as? String == overlay.layerIdentifier })
                    let layout = try #require(layer["layout"] as? [String: Any])
                    if overlay == .essentials {
                        let expression = try #require(layout["icon-image"] as? [Any])
                        #expect(expression.first as? String == "match")
                        let images = Set(expression.compactMap { $0 as? String }.filter { $0.hasPrefix("harta-essential-") })
                        #expect(images == Set(EssentialKind.allCases.map(\.imageName)))
                    }
                    if overlay == .transit {
                        let expression = try #require(layout["icon-image"] as? [Any])
                        #expect(expression.first as? String == "match")
                        let images = Set(expression.compactMap { $0 as? String }.filter { $0.hasPrefix("harta-transit-") })
                        #expect(images == Set(TransitKind.allCases.map(\.imageName)))
                    }
                    #expect(layout["visibility"] as? String == "none")
                    #expect(layer["source-layer"] as? String == (overlay == .cycling ? "transportation" : "poi"))
                    if overlay != .cycling && overlay != .transit && overlay != .essentials {
                        #expect(layout["icon-image"] as? String == overlay.layerIdentifier)
                    }
                }
            }
        }
    }

    @Test func overlaySelectionsAreIndependent() {
        var selection = 0
        for overlay in MapOverlay.allCases {
            #expect(!overlay.isEnabled(in: selection))
            selection |= overlay.rawValue
            #expect(overlay.isEnabled(in: selection))
        }
        #expect(MapOverlay.enabledCount(in: selection) == 6)
        selection &= ~MapOverlay.chargers.rawValue
        #expect(!MapOverlay.chargers.isEnabled(in: selection))
        #expect(MapOverlay.toilets.isEnabled(in: selection))
        #expect(MapOverlay.enabledCount(in: selection) == 5)
    }

}
