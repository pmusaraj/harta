enum MapSheet: String, Identifiable {
    case saved, place, settings, layers
    var id: String { rawValue }
}
