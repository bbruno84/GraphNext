//
//  CKRecord+GraphNext.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import CloudKit
import Foundation

/// Global threshold (bytes) to decide whether to attach CKAsset on push.
/// Set from CloudKitSync.configuration.assetThresholdBytes at CloudKitSync init.
enum _CKAttachmentThreshold {
    static var bytes: Int = 15 * 1024 * 1024 // default 15 MB
}

extension Entity {
    func asCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Entity", recordID: CKRecord.ID(recordName: self.id.uuidString))
        record["uuid"] = self.id.uuidString as CKRecordValue
        record["type"] = self.type as CKRecordValue
        
        if let payloadData = try? JSONEncoder().encode(self.payload) {
            record["payload"] = payloadData as CKRecordValue
        }
        
        // Attach CKAsset for file-backed assets, if a local URL is available and under threshold.
        if self.type == "asset" {
            if let fileURL = try? AssetStorageProvider.shared.storage.urlIfPresent(assetId: self.id) {
                if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let size = values.fileSize,
                   size <= _CKAttachmentThreshold.bytes {
                    record["file"] = CKAsset(fileURL: fileURL)
                } else {
                    // Over threshold or unknown size: keep only metadata in payload
                    // (intentionally skip attaching CKAsset)
                    print("Asset over threshold: \(fileURL), skipping attachment")
                }
            }
        }
        
        record["sharedWith"] = self.sharedWith as CKRecordValue
        
        record["createdBy"] = self.created.by as CKRecordValue
        record["createdAt"] = self.created.at as CKRecordValue
        
        if let updated = self.updated {
            record["updatedBy"] = updated.by as CKRecordValue
            record["updatedAt"] = updated.at as CKRecordValue
        }
        
        return record
    }
}

extension Relationship {
    func asCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Relationship", recordID: CKRecord.ID(recordName: self.id.uuidString))
        record["uuid"] = self.id.uuidString as CKRecordValue
        record["type"] = self.type as CKRecordValue
        
        if let from = self.from {
            record["sourceUUID"] = from.uuidString as CKRecordValue
        }
        if let to = self.to {
            record["targetUUID"] = to.uuidString as CKRecordValue
        }
        
        record["sharedWith"] = self.sharedWith as CKRecordValue
        
        record["createdBy"] = self.created.by as CKRecordValue
        record["createdAt"] = self.created.at as CKRecordValue
        
        if let updated = self.updated {
            record["updatedBy"] = updated.by as CKRecordValue
            record["updatedAt"] = updated.at as CKRecordValue
        }
        
        return record
    }
}
