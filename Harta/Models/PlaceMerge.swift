import Foundation

/// Applies local changes since the last successful sync to the latest cloud snapshot.
/// Independent place edits survive; a local change wins a conflict on the same place.
enum PlaceMerge {
    static func merge(baseline: [Place], local: [Place], remote: [Place]) -> [Place] {
        let before = Dictionary(baseline.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        let current = Dictionary(local.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        let deleted = Set(before.keys).subtracting(current.keys)
        let changed = local.filter { before[$0.id] != $0 }
        let changedIDs = Set(changed.map(\.id))
        return changed + remote.filter { !deleted.contains($0.id) && !changedIDs.contains($0.id) }
    }
}
