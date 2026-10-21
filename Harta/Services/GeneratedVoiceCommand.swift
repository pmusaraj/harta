import FoundationModels

@Generable
struct GeneratedVoiceCommand {
    @Generable enum Action: String { case search, directions }
    @Generable enum Mode: String { case walking, cycling, driving }
    var action: Action
    @Guide(description: "The place name or address as spoken, or home/work. No invented destination.")
    var destination: String
    @Guide(description: "Explicit city or locality qualifier only; nil when not spoken.")
    var locality: String?
    @Guide(description: "Travel mode only if explicitly requested.")
    var mode: Mode?
    @Guide(description: "True for requests requiring opening hours, ratings, prices, distance filters, availability, or actions other than search/directions.")
    var unsupported: Bool
}
