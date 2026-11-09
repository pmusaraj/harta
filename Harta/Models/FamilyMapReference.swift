import CloudKit

struct FamilyMapReference: Codable, Equatable {
    let recordName: String
    let zoneName: String
    let ownerName: String

    init(_ id: CKRecord.ID) {
        recordName = id.recordName
        zoneName = id.zoneID.zoneName
        ownerName = id.zoneID.ownerName
    }

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: recordName, zoneID: CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName))
    }
}
