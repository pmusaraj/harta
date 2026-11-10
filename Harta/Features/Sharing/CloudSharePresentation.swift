import CloudKit

struct CloudSharePresentation: Identifiable {
    let share: CKShare
    var id: CKRecord.ID { share.recordID }
}
